import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../widgets/hand_view.dart';
import '../widgets/anatomy_hand_view.dart';
import '../widgets/finger_bars.dart';
import '../widgets/quality_strip.dart';
import '../theme/app_theme.dart';
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
  bool _showAnatomicalSkeleton = false;
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
    final c = AppColors.of(context);
    final dev = widget.deviceService;
    final plan = widget.storageService.activePlan;
    final isLiveStreaming = dev.state == DeviceConnectionState.streaming;

    final minutes = (_sessionSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_sessionSeconds % 60).toString().padLeft(2, '0');

    // Fatigue status
    final fatigueResult = FatigueCalculator.compute(
      completedReps: _completedReps,
      thresholdPct: plan.fatigueDropThreshold,
    );

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: c.isDark ? const Color(0xFF0B0F0E) : Colors.white,
        leading: BackButton(color: c.textPrimary),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.name.toUpperCase(),
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isLiveStreaming ? const Color(0xFFC8F05F) : const Color(0xFFF5A623),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isLiveStreaming ? 'LIVE SENSOR HUD (50 Hz)' : 'OFFLINE MODE',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Play / Pause Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isPaused ? const Color(0xFFC8F05F) : (c.isDark ? const Color(0xFF1E2822) : const Color(0xFFF0F4EC)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: _isPaused ? const Color(0xFF121715) : c.textPrimary,
                size: 18,
              ),
            ),
            onPressed: _togglePause,
          ),

          // Stop / Finish Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
            onPressed: _confirmEndSession,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Stop Instruction Banner (Themed for high contrast and elegance)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: c.isDark ? const Color(0xFF1B160C) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: c.isDark ? const Color(0xFF8A6518).withOpacity(0.4) : const Color(0xFFFFE082),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 13,
                      color: c.isDark ? const Color(0xFFFFD38A) : const Color(0xFF8D6E63),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        plan.stopInstruction,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.isDark ? const Color(0xFFFFD38A) : const Color(0xFF8D6E63),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 2. Stream Quality Strip
              QualityStripWidget(
                isConnected: isLiveStreaming,
                isSimulated: dev.isSimulated,
                packetRateHz: dev.currentPacketRateHz,
                lastPacketAgeMs: dev.lastPacketAgeMs,
                dataQuality: dev.currentDataQuality,
              ),
              const SizedBox(height: 12),

              // 3. Telemetry Cockpit Row (Time, Repetitions, Live ROM)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.cardBorder, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(c.isDark ? 0.35 : 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // A. Time Tile
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 12, color: c.lime),
                              const SizedBox(width: 4),
                              Text(
                                'TIME',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$minutes:$seconds',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _isPaused ? 'PAUSED' : 'ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _isPaused ? const Color(0xFFF5A623) : c.lime,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(width: 1, height: 42, color: c.cardBorder),

                    // B. Repetitions Progress Tile
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.fitness_center, size: 12, color: Color(0xFF56B4E9)),
                                const SizedBox(width: 4),
                                Text(
                                  'REPS',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${_completedReps.length}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: c.textPrimary,
                                  ),
                                ),
                                Text(
                                  ' / ${plan.targetReps}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _stateLabel(_repDetector.state),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _stateColor(_repDetector.state, c),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(width: 1, height: 42, color: c.cardBorder),

                    // C. Live ROM Tile
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.show_chart, size: 12, color: Color(0xFFF5A623)),
                                const SizedBox(width: 4),
                                Text(
                                  'FLEXION',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_currentSignal.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'TARGET: ${plan.targetRomMin.toInt()}%+',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _currentSignal >= plan.targetRomMin ? c.lime : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Live Feedback / Hold Banner
              if (_repDetector.state == RepetitionState.peakHold)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F05F).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC8F05F)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app, size: 16, color: Color(0xFFC8F05F)),
                      const SizedBox(width: 8),
                      Text(
                        'HOLD POSITION! (${plan.holdS.toStringAsFixed(1)}s)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Color(0xFFC8F05F),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_activeFeedbackMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF5A623)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFF5A623)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _activeFeedbackMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD38A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Fatigue Warning
              if (fatigueResult.isAvailable && fatigueResult.isFatigueDetected)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.battery_alert, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fatigueResult.message ?? 'Fatigue detected: ROM is dropping. Rest as needed.',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 6. View Switcher Strip (3D HUMAN HAND vs 3D SKELETON)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: c.isDark ? const Color(0xFF141816) : const Color(0xFFE8ECE9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.cardBorder, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _build3DViewTab('3D HUMAN HAND', !_showAnatomicalSkeleton, () {
                          setState(() => _showAnatomicalSkeleton = false);
                        }),
                        const SizedBox(width: 3),
                        _build3DViewTab('3D SKELETON ANATOMY', _showAnatomicalSkeleton, () {
                          setState(() => _showAnatomicalSkeleton = true);
                        }),
                      ],
                    ),
                  ),

                  // Sensor Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.isDark ? const Color(0xFF141816) : const Color(0xFFE8ECE9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: c.cardBorder, width: 0.8),
                    ),
                    child: Text(
                      isLiveStreaming ? 'LIVE SENSOR' : 'SIMULATED',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isLiveStreaming ? c.lime : c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 7. THE BIG 3D HAND VIEW (Main Stage Hero Element)
              // Generous 300px height, centered, upright, full width
              _showAnatomicalSkeleton
                  ? AnatomyHandView(
                      normalizedFlex: _displayFlex,
                      imu: dev.latestPacket?.imu,
                      isConnected: isLiveStreaming,
                    )
                  : HandView(
                      normalizedFlex: _displayFlex,
                      imu: dev.latestPacket?.imu,
                      isConnected: isLiveStreaming,
                      height: 300,
                      showRenderModeSelector: true,
                    ),
              const SizedBox(height: 16),

              // 8. Bottom Section: 5 Finger Flexion Bars & Palmar FSR Contact
              FingerBarsWidget(
                normalizedFlex: _displayFlex,
                fsrContact: (dev.latestPacket?.fsr ?? 0) / 32767.0 * 100.0,
                targetRomMin: plan.targetRomMin,
                targetRomMax: plan.targetRomMax,
                isConnected: isLiveStreaming,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DViewTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8F05F) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: isSelected ? const Color(0xFF121715) : const Color(0xFF8E958E),
          ),
        ),
      ),
    );
  }

  String _stateLabel(RepetitionState state) {
    switch (state) {
      case RepetitionState.idle:
        return 'WAITING';
      case RepetitionState.rising:
        return 'MOVING';
      case RepetitionState.peakHold:
        return 'HOLDING';
      case RepetitionState.falling:
        return 'RETURNING';
      case RepetitionState.complete:
        return 'DONE';
      case RepetitionState.rejected:
        return 'RESET';
    }
  }

  Color _stateColor(RepetitionState state, AppColors c) {
    switch (state) {
      case RepetitionState.idle:
        return c.textSecondary;
      case RepetitionState.rising:
      case RepetitionState.falling:
        return const Color(0xFF56B4E9);
      case RepetitionState.peakHold:
        return const Color(0xFFF5A623);
      case RepetitionState.complete:
        return c.lime;
      case RepetitionState.rejected:
        return const Color(0xFFEF4444);
    }
  }
}
