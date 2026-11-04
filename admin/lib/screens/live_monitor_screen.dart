import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/repetition_ring.dart';
import '../widgets/finger_bars.dart';
import '../widgets/quality_strip.dart';
import '../widgets/web_hand_viewer.dart';

class LiveMonitorScreen extends StatefulWidget {
  final ApiService apiService;
  final String? initialPatientId;

  const LiveMonitorScreen({
    super.key,
    required this.apiService,
    this.initialPatientId,
  });

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  late String _selectedPatient;
  bool _isLiveStreaming = true;
  bool _isPaused = false;
  int _sessionSeconds = 2;
  Timer? _sessionTimer;
  Timer? _telemetryTimer;

  int _currentRep = 0;
  final int _targetReps = 10;
  RepetitionState _repState = RepetitionState.idle;
  double _simPhase = 0.0;
  HandRenderMode _currentMode = HandRenderMode.skin;

  List<double> _liveFlex = [0.0, 0.0, 0.0, 0.0, 0.0];
  double _fsrContact = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatientId ?? 'P-014';

    // 1-second clock timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && _isLiveStreaming && mounted) {
        setState(() => _sessionSeconds++);
      }
    });

    // 25 Hz telemetry frame loop (~40ms)
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_isPaused && _isLiveStreaming && mounted) {
        _tickTelemetry();
      }
    });
  }

  void _tickTelemetry() {
    _simPhase += 0.05;
    final wave = (math.sin(_simPhase) * 0.5 + 0.5).clamp(0.0, 1.0);

    // Compute synthetic flex simulation for clinical demonstration
    final thumb = (wave * 82.0).clamp(0.0, 100.0);
    final index = (wave * 94.0).clamp(0.0, 100.0);
    final middle = (wave * 88.0).clamp(0.0, 100.0);
    final ring = (middle * 0.90).clamp(0.0, 100.0);
    final pinky = (middle * 0.75).clamp(0.0, 100.0);

    // State transition simulation based on flexion
    RepetitionState nextState;
    if (wave < 0.15) {
      nextState = RepetitionState.idle;
    } else if (wave < 0.70 && math.cos(_simPhase) > 0) {
      nextState = RepetitionState.rising;
    } else if (wave >= 0.70) {
      nextState = RepetitionState.peakHold;
    } else {
      nextState = RepetitionState.falling;
    }

    if (_repState == RepetitionState.peakHold && nextState == RepetitionState.falling) {
      _currentRep = (_currentRep + 1) % (_targetReps + 1);
    }

    setState(() {
      _liveFlex = [thumb, index, middle, ring, pinky];
      _fsrContact = wave * 68.0;
      _repState = nextState;
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = widget.apiService.patients;
    final plan = widget.apiService.getPatientActivePlan(_selectedPatient);

    final minutes = (_sessionSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_sessionSeconds % 60).toString().padLeft(2, '0');
    final elapsedStr = '$minutes:$seconds';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Session Protocol Header with Back, Title, Pause, Stop (Screenshot 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Patient selector pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A17),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF222B26)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPatient,
                          dropdownColor: const Color(0xFF161E1A),
                          icon: const Icon(Icons.arrow_drop_down, color: AdminTheme.lime, size: 16),
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          items: patients.map((p) {
                            return DropdownMenuItem(
                              value: p.pseudonym,
                              child: Text('Patient ${p.pseudonym}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPatient = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        (plan?.exerciseId ?? 'FINGERTAP').replaceAll('_', '').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: AdminTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pause / Play
                  IconButton(
                    icon: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: _isPaused ? AdminTheme.lime : AdminTheme.textPrimary,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _isPaused = !_isPaused),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const SizedBox(width: 2),
                  // Stop Button
                  IconButton(
                    icon: const Icon(Icons.stop_rounded, color: AdminTheme.crimson, size: 18),
                    onPressed: () {
                      setState(() {
                        _isLiveStreaming = false;
                        _liveFlex = [0, 0, 0, 0, 0];
                        _fsrContact = 0.0;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Safety Stop Instruction Banner (Screenshot 3)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              plan?.stopInstruction ?? 'Stop if you feel sharp pain. Rest as needed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4420),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Stream Quality Strip (Screenshot 3)
          QualityStripWidget(
            isConnected: _isLiveStreaming,
            isSimulated: true,
            packetRateHz: _isLiveStreaming ? 25.0 : 0.0,
            lastPacketAgeMs: _isLiveStreaming ? 40 : 1200,
            dataQuality: _isLiveStreaming ? 'good' : 'bad',
          ),
          const SizedBox(height: 14),

          // 4. Main Cockpit Row: Repetition Ring (Left) + 3D Hand HUD Stage (Right) (Screenshot 3)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final ringWidget = Center(
                child: RepetitionRingWidget(
                  completedReps: _currentRep,
                  targetReps: plan?.targetReps ?? _targetReps,
                  state: _repState,
                  elapsedText: elapsedStr,
                  size: isNarrow ? 150 : 170,
                ),
              );

              final handWidget = Container(
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFF070A09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222B26), width: 1.0),
                ),
                child: Stack(
                  children: [
                    // Forward Kinematic Anatomical Hand Viewer
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: WebHandViewer(
                          normalizedFlex: _liveFlex,
                          isConnected: _isLiveStreaming,
                          renderMode: _currentMode,
                        ),
                      ),
                    ),

                    // Top Mode Selector: SKIN | MESH | XRAY + NO DEVICE / 3D HUD ON (Screenshot 3)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14120E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2E261A), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildModeButton(HandRenderMode.skin, 'SKIN'),
                                _buildModeButton(HandRenderMode.mesh, 'MESH'),
                                _buildModeButton(HandRenderMode.xray, 'XRAY'),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141A17),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isLiveStreaming ? AdminTheme.lime.withOpacity(0.4) : const Color(0xFFF5A623).withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              _isLiveStreaming ? '3D HUD: ON' : 'NO DEVICE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: _isLiveStreaming ? AdminTheme.lime : const Color(0xFFF5A623),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    ringWidget,
                    const SizedBox(height: 14),
                    handWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 4, child: ringWidget),
                  const SizedBox(width: 14),
                  Expanded(flex: 5, child: handWidget),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // 5. Finger Flexion & Palmar Contact Card (Screenshot 3)
          FingerBarsWidget(
            normalizedFlex: _liveFlex,
            fsrContact: _isLiveStreaming ? _fsrContact : null,
            targetRomMin: plan?.targetRomMin ?? 70.0,
            targetRomMax: plan?.targetRomMax ?? 100.0,
            isConnected: _isLiveStreaming,
          ),
          const SizedBox(height: 70), // breathing room above floating dock
        ],
      ),
    );
  }

  Widget _buildModeButton(HandRenderMode mode, String label) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5A623) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: isSelected ? const Color(0xFF0B0F0E) : AdminTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
