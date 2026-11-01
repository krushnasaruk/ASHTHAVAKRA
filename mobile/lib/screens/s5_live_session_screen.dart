import 'dart:async';
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../widgets/hand_visualization.dart';
import '../widgets/finger_bars.dart';
import '../widgets/repetition_ring.dart';
import '../widgets/quality_strip.dart';
import 's6_summary_screen.dart';

class LiveSessionScreen extends StatefulWidget {
  final ExerciseCode exercise;
  final DeviceService deviceService;
  final StorageService storageService;

  const LiveSessionScreen({
    super.key,
    required this.exercise,
    required this.deviceService,
    required this.storageService,
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  late RepetitionDetector _repDetector;
  final ExerciseSignalExtractor _signalExtractor = ExerciseSignalExtractor();
  final String _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

  bool _isPaused = false;
  int _sessionSeconds = 0;
  Timer? _sessionTimer;
  Timer? _presentationTimer;

  final List<Repetition> _completedReps = [];
  final List<double> _repRoms = [];
  String? _activeFeedbackMessage;
  double _currentSignal = 0.0;
  List<double> _displayFlex = [0, 0, 0, 0, 0];

  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    final plan = widget.storageService.activePlan;
    _repDetector = RepetitionDetector(
      upperThreshold: plan.targetRomMin,
      lowerThreshold: 30.0,
      minDurationS: 0.6,
      maxDurationS: 8.0,
      holdBandPct: 5.0,
      minHoldDurationS: plan.holdS,
      debounceMs: 300,
    );

    // 1-second session clock
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) {
        setState(() => _sessionSeconds++);
      }
    });

    // 30 fps Presentation Sampler (~33ms) independent of 50 Hz processing rate
    _presentationTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!_isPaused && mounted) {
        _processSampleTick();
      }
    });
  }

  void _processSampleTick() {
    final dev = widget.deviceService;
    final packet = dev.latestPacket;
    if (packet == null) return;

    // Check connection loss -> Auto-pause
    if (dev.state == DeviceConnectionState.disconnected || dev.state == DeviceConnectionState.degraded) {
      if (!_isPaused) {
        setState(() {
          _isPaused = true;
          _activeFeedbackMessage = 'Connection interrupted, session paused.';
        });
      }
      return;
    }

    final normFlex = dev.latestNormalizedFlex;
    _displayFlex = List<double>.from(normFlex);

    // Extract exercise driving signal
    _currentSignal = _signalExtractor.extractSignal(
      exercise: widget.exercise,
      normalizedFlex: normFlex,
      imu: packet.imu,
      timestampMs: packet.timestampMs,
    );

    // Feed to hysteresis detector
    final repResult = _repDetector.processSample(
      signal: _currentSignal,
      timestampMs: packet.timestampMs,
      sessionId: _sessionId,
    );

    if (repResult != null) {
      if (repResult.status == RepetitionStatus.complete) {
        _completedReps.add(repResult);
        _repRoms.add(repResult.rom);
        _activeFeedbackMessage = null; // Clear warning on success
      } else if (repResult.status == RepetitionStatus.rejected) {
        if (repResult.rejectReason == 'too_fast') {
          _activeFeedbackMessage = 'Slow down! Move with controlled speed.';
        } else if (repResult.rejectReason == 'incomplete') {
          _activeFeedbackMessage = 'Open your hand further to reach target.';
        }
      }
    }

    // Dynamic Hold and ROM Feedback
    if (_repDetector.state == RepetitionState.peakHold) {
      _activeFeedbackMessage = 'Hold the position...';
    }

    setState(() {});
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _activeFeedbackMessage = 'Session Paused';
      } else {
        _activeFeedbackMessage = null;
      }
    });
  }

  Future<void> _confirmEndSession() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Rehabilitation Session?'),
        content: Text('You have completed ${_completedReps.length} repetitions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Resume')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(H10Tokens.colorError), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End & Save'),
          ),
        ],
      ),
    );

    if (shouldEnd == true && mounted) {
      _finishAndOpenSummary();
    }
  }

  void _finishAndOpenSummary() {
    _sessionTimer?.cancel();
    _presentationTimer?.cancel();

    final plan = widget.storageService.activePlan;
    final meanRom = _repRoms.isNotEmpty ? _repRoms.reduce((a, b) => a + b) / _repRoms.length : 0.0;
    final maxRom = _repRoms.isNotEmpty ? _repRoms.reduce((a, b) => a > b ? a : b) : 0.0;

    final consistency = ConsistencyCalculator.compute(
      completedReps: _completedReps,
      targetPeak: plan.targetRomMin,
    );

    final fatigue = FatigueCalculator.compute(
      completedReps: _completedReps,
      thresholdPct: plan.fatigueDropThreshold,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          sessionId: _sessionId,
          exercise: widget.exercise,
          durationS: _sessionSeconds.toDouble(),
          completedReps: _completedReps,
          meanRom: meanRom,
          maxRom: maxRom,
          consistency: consistency,
          fatigue: fatigue,
          storageService: widget.storageService,
          deviceService: widget.deviceService,
          startedAt: _startedAt ?? DateTime.now(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _presentationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dev = widget.deviceService;
    final plan = widget.storageService.activePlan;
    final minutes = (_sessionSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_sessionSeconds % 60).toString().padLeft(2, '0');

    // Fatigue status
    final fatigueResult = FatigueCalculator.compute(
      completedReps: _completedReps,
      thresholdPct: plan.fatigueDropThreshold,
    );

    return Scaffold(
      backgroundColor: const Color(H10Tokens.colorBackground),
      appBar: AppBar(
        title: Text(widget.exercise.name.toUpperCase()),
        backgroundColor: const Color(H10Tokens.colorBackground),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Color(H10Tokens.colorError)),
            onPressed: _confirmEndSession,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stop Instruction Banner (always visible per spec)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFFFF8E1),
              child: Text(
                plan.stopInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8D6E63)),
              ),
            ),

            // Quality Strip
            Padding(
              padding: const EdgeInsets.all(H10Tokens.space12),
              child: QualityStripWidget(
                isConnected: dev.state == DeviceConnectionState.streaming,
                isSimulated: dev.isSimulated,
                packetRateHz: dev.currentPacketRateHz,
                lastPacketAgeMs: dev.lastPacketAgeMs,
                dataQuality: dev.currentDataQuality,
              ),
            ),

            // Live Feedback Banner
            if (_activeFeedbackMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: H10Tokens.space12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(H10Tokens.colorWarning)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Color(H10Tokens.colorWarning)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeFeedbackMessage!,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorWarning)),
                      ),
                    ),
                  ],
                ),
              ),

            // Fatigue Indicator (Appears after 6 reps)
            if (fatigueResult.isAvailable && fatigueResult.isFatigueDetected)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: H10Tokens.space12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.battery_alert, size: 16, color: Color(H10Tokens.colorError)),
                    const SizedBox(width: 6),
                    Text(
                      fatigueResult.message ?? 'Fatigue detected: ROM is dropping',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorError)),
                    ),
                  ],
                ),
              ),

            // Central Display: Repetition Ring & Animated 2D Hand
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: H10Tokens.space16),
                child: Row(
                  children: [
                    // Left: Repetition Ring & Timer
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$minutes:$seconds', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                          const SizedBox(height: 12),
                          RepetitionRingWidget(
                            completedReps: _completedReps.length,
                            targetReps: plan.targetReps,
                            state: _repDetector.state,
                            size: 130,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Current ROM: ${_currentSignal.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(H10Tokens.colorPrimary)),
                          ),
                        ],
                      ),
                    ),

                    // Right: Animated 2D Hand Visualization (30 fps)
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: HandVisualizationWidget(
                          movement: HandMovement(
                            thumb: _displayFlex[0],
                            index: _displayFlex[1],
                            middle: _displayFlex[2],
                            ring: _displayFlex[3],
                            pinky: _displayFlex[4],
                          ),
                          width: 180,
                          height: 220,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section: 5 Finger Flexion Bars & End Controls (Lower third)
            Padding(
              padding: const EdgeInsets.all(H10Tokens.space12),
              child: FingerBarsWidget(
                normalizedFlex: _displayFlex,
                targetRomMin: plan.targetRomMin,
                targetRomMax: plan.targetRomMax,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
