import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../widgets/hand_visualization.dart';
import '../widgets/finger_bars.dart';
import '../widgets/repetition_ring.dart';
import '../widgets/quality_strip.dart';
import '../widgets/holographic_hand_scan.dart';
import '../dev/mock_data.dart';
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
  bool _showHolographic3D = true;
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

  double _simPhase = 0.0;

  void _processSampleTick() {
    final dev = widget.deviceService;
    final packet = dev.latestPacket;
    final isLiveStreaming = packet != null && dev.state == DeviceConnectionState.streaming;

    List<double> normFlex;
    List<int> imu;
    int timestampMs;

    if (isLiveStreaming) {
      normFlex = dev.latestNormalizedFlex;
      imu = packet.imu;
      timestampMs = packet.timestampMs;
    } else if (kUseMockData) {
      _simPhase += 0.04;
      final wave = (math.sin(_simPhase) * 0.5 + 0.5) * 88.0;
      normFlex = [wave, wave, wave, wave, wave];
      imu = [0, -980, 0, 0, 0, 0];
      timestampMs = _sessionSeconds * 1000 + ((_simPhase * 100).toInt() % 1000);
    } else {
      // Hardware / real mode: use actual device readings without fabricating synthetic waves
      normFlex = dev.latestNormalizedFlex;
      imu = packet?.imu ?? [0, 0, 0, 0, 0, 0];
      timestampMs = packet?.timestampMs ?? (_sessionSeconds * 1000);
    }

    _displayFlex = List<double>.from(normFlex);

    // Extract exercise driving signal
    _currentSignal = _signalExtractor.extractSignal(
      exercise: widget.exercise,
      normalizedFlex: normFlex,
      imu: imu,
      timestampMs: timestampMs,
    );

    // Feed to hysteresis detector
    final repResult = _repDetector.processSample(
      signal: _currentSignal,
      timestampMs: timestampMs,
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

                    // Right: Animated 3D Holographic or 2D Hand Visualization
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showHolographic3D = !_showHolographic3D;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _showHolographic3D ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _showHolographic3D ? const Color(0xFF00E5FF) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Text(
                                    _showHolographic3D ? '3D HUD' : '2D VIEW',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _showHolographic3D ? const Color(0xFF00E5FF) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: _showHolographic3D
                                ? SizedBox(
                                    width: 195,
                                    height: 215,
                                    child: HolographicHandScanWidget(
                                      flexValues: _displayFlex,
                                      fsrContact: (widget.deviceService.latestPacket?.fsr ?? 0) / 32767.0 * 100.0,
                                      isDemo3: widget.deviceService.hardwareProfile == 'demo3',
                                    ),
                                  )
                                : HandVisualizationWidget(
                                    movement: HandMovement(
                                      thumb: _displayFlex[0],
                                      index: _displayFlex[1],
                                      middle: _displayFlex[2],
                                      ring: _displayFlex[3],
                                      pinky: _displayFlex[4],
                                    ),
                                    width: 180,
                                    height: 215,
                                  ),
                          ),
                        ],
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

