import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import 's6_summary_screen.dart';

class MiniGameScreen extends StatefulWidget {
  final DeviceService deviceService;
  final StorageService storageService;

  const MiniGameScreen({
    super.key,
    required this.deviceService,
    required this.storageService,
  });

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  int _score = 0;
  int _misses = 0;
  int _targetFinger = 1; // Index finger
  double _targetHeight = 0.5; // 0.0 to 1.0
  double _objectX = 0.0; // 0.0 to 1.0 (left to right)
  Timer? _gameLoopTimer;

  bool _isGameOver = false;
  final int _gameDurationSeconds = 60;
  int _elapsedSeconds = 0;
  double _manualFlex = 50.0;
  final List<Repetition> _gameReps = [];

  double get _currentFlex {
    if (widget.deviceService.state == DeviceConnectionState.streaming) {
      return widget.deviceService.latestNormalizedFlex[_targetFinger];
    }
    return _manualFlex;
  }

  @override
  void initState() {
    super.initState();
    _spawnNewTarget();
    _startGameLoop();
  }

  void _spawnNewTarget() {
    final rng = math.Random();
    _targetFinger = rng.nextInt(5); // Random finger (0 to 4)
    _targetHeight = 0.3 + (rng.nextDouble() * 0.5); // Target height 30% to 80%
    _objectX = 0.0;
  }

  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted || _isGameOver) return;

      setState(() {
        _objectX += 0.015; // Move across screen

        // Check if object reaches the catch zone (x >= 0.85)
        if (_objectX >= 0.85 && _objectX <= 0.95) {
          final currentFlex = _currentFlex / 100.0;
          // Catch window: within ±15% of target height
          if ((currentFlex - _targetHeight).abs() <= 0.15) {
            _score++;
            _gameReps.add(Repetition(
              id: 'game_rep_$_score',
              sessionId: 'game_session',
              index: _score,
              startMs: _elapsedSeconds * 1000,
              endMs: _elapsedSeconds * 1000 + 500,
              durationS: 0.5,
              peak: currentFlex * 100.0,
              mean: currentFlex * 100.0,
              min: 0.0,
              rom: currentFlex * 100.0,
              holdS: 0.2,
              status: RepetitionStatus.complete,
            ));
            _spawnNewTarget();
          }
        } else if (_objectX > 1.0) {
          _misses++;
          _spawnNewTarget();
        }
      });
    });

    // Clock
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isGameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds >= _gameDurationSeconds) {
          _isGameOver = true;
          _finishGame();
        }
      });
    });
  }

  void _finishGame() {
    _gameLoopTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          sessionId: 'game_${DateTime.now().millisecondsSinceEpoch}',
          exercise: ExerciseCode.handControlGame,
          durationS: _elapsedSeconds.toDouble(),
          completedReps: _gameReps,
          meanRom: _score > 0 ? 75.0 : 0.0,
          maxRom: 85.0,
          consistency: const ConsistencyResult(isAvailable: false, missingReason: 'Mini-game uses catch accuracy instead of rep consistency'),
          fatigue: const FatigueResult(isAvailable: false, isFatigueDetected: false),
          storageService: widget.storageService,
          deviceService: widget.deviceService,
          startedAt: DateTime.now().subtract(Duration(seconds: _elapsedSeconds)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fingerName = H10Tokens.fingerNames[_targetFinger];
    final fingerColor = Color(H10Tokens.fingerColors[_targetFinger]);
    final curFlex = _currentFlex;

    return Scaffold(
      backgroundColor: const Color(H10Tokens.colorBackground),
      appBar: AppBar(
        title: const Text('Hand Control Challenge'),
        backgroundColor: const Color(H10Tokens.colorBackground),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(H10Tokens.space16),
          child: Column(
            children: [
              // Score Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Caught: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorSuccess))),
                  Text('Time: ${_gameDurationSeconds - _elapsedSeconds}s', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Misses: $_misses', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorError))),
                ],
              ),
              const SizedBox(height: 12),

              // Instruction Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fingerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: fingerColor),
                ),
                child: Text(
                  'FLEX $fingerName TO ${( _targetHeight * 100).toStringAsFixed(0)}% TO CATCH!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: fingerColor),
                ),
              ),
              const SizedBox(height: 16),

              // Game Arena
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final arenaWidth = constraints.maxWidth;
                    final arenaHeight = constraints.maxHeight;

                    final targetTop = (1.0 - _targetHeight) * (arenaHeight - 50);
                    final objectLeft = _objectX * (arenaWidth - 40);
                    final playerTop = (1.0 - (curFlex / 100.0).clamp(0.0, 1.0)) * (arenaHeight - 50);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                        border: Border.all(color: const Color(H10Tokens.colorBorder)),
                      ),
                      child: Stack(
                        children: [
                          // Target Zone (right side catch bar)
                          Positioned(
                            right: 20,
                            top: targetTop,
                            child: Container(
                              width: 30,
                              height: 50,
                              decoration: BoxDecoration(
                                color: fingerColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: fingerColor, width: 2),
                              ),
                            ),
                          ),

                          // Moving Target Object
                          Positioned(
                            left: objectLeft.clamp(0.0, arenaWidth - 30),
                            top: targetTop + 10,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(H10Tokens.colorWarning),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 4)],
                              ),
                            ),
                          ),

                          // Player Catch Cursor (controlled by finger flexion)
                          Positioned(
                            right: 20,
                            top: playerTop.clamp(0.0, arenaHeight - 40),
                            child: Container(
                              width: 30,
                              height: 12,
                              decoration: BoxDecoration(
                                color: fingerColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Interactive Control Slider (For mouse/touch demo or calibration)
              if (widget.deviceService.state != DeviceConnectionState.streaming) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(H10Tokens.colorBorder)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mouse / Touch Control: $fingerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('${_manualFlex.toStringAsFixed(0)}% ROM', style: TextStyle(fontWeight: FontWeight.bold, color: fingerColor)),
                        ],
                      ),
                      Slider(
                        value: _manualFlex,
                        min: 0,
                        max: 100,
                        activeColor: fingerColor,
                        onChanged: (val) => setState(() => _manualFlex = val),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Live Flex Feedback
              Text(
                '$fingerName Flexion: ${curFlex.toStringAsFixed(0)}% (Target: ${(_targetHeight * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: fingerColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
