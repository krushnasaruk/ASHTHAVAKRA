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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Session Protocol Header with Patient Selector, Protocol Name, Pause, Stop
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Patient selector pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminTheme.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPatient,
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.arrow_drop_down, color: AdminTheme.textPrimary, size: 18),
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            items: patients.map((p) {
                              return DropdownMenuItem(
                                value: p.pseudonym,
                                child: Text('Patient ${p.pseudonym}', style: const TextStyle(color: AdminTheme.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPatient = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          (plan?.exerciseId ?? 'FINGERTAP').replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: AdminTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AdminTheme.lime,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE PROTOCOL',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14181B),
                          ),
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
                        color: _isPaused ? AdminTheme.green : AdminTheme.textPrimary,
                        size: 20,
                      ),
                      tooltip: _isPaused ? 'Resume Session' : 'Pause Session',
                      onPressed: () => setState(() => _isPaused = !_isPaused),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 4),
                    // Stop Button
                    IconButton(
                      icon: const Icon(Icons.stop_rounded, color: AdminTheme.crimson, size: 20),
                      tooltip: 'Emergency Stop',
                      onPressed: () {
                        setState(() {
                          _isLiveStreaming = false;
                          _liveFlex = [0, 0, 0, 0, 0];
                          _fsrContact = 0.0;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Safety Stop Instruction Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082), width: 1.0),
            ),
            child: Text(
              plan?.stopInstruction ?? 'Stop if you feel sharp pain. Rest as needed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4420),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Stream Quality Strip
          QualityStripWidget(
            isConnected: _isLiveStreaming,
            isSimulated: true,
            packetRateHz: _isLiveStreaming ? 25.0 : 0.0,
            lastPacketAgeMs: _isLiveStreaming ? 40 : 1200,
            dataQuality: _isLiveStreaming ? 'good' : 'bad',
          ),
          const SizedBox(height: 14),

          // 4. Laptop Clinical Cockpit: Expansive 3D Anatomical Hand (Left) + Telemetry / Ring (Right)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWidescreen = constraints.maxWidth >= 768;

              final handWidget = Container(
                height: isWidescreen ? 540 : 320,
                decoration: BoxDecoration(
                  color: const Color(0xFF040605),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222B26), width: 1.0),
                ),
                child: Stack(
                  children: [
                    // Forward Kinematic 3D Multi-Skin Hand Viewer (WebGL Three.js)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: WebHandViewer(
                          normalizedFlex: _liveFlex,
                          isConnected: _isLiveStreaming,
                          renderMode: _currentMode,
                          fsrContact: _fsrContact,
                          height: isWidescreen ? 540 : 320,
                          showControls: true,
                        ),
                      ),
                    ),

                    // Top Multi-Skin Selector: SKIN | MESH | XRAY | SKELETON | HOLOGRAPHIC
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14120E).withOpacity(0.92),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2E261A), width: 0.8),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildModeButton(HandRenderMode.skin, 'SKIN'),
                                    const SizedBox(width: 2),
                                    _buildModeButton(HandRenderMode.mesh, 'MESH'),
                                    const SizedBox(width: 2),
                                    _buildModeButton(HandRenderMode.xray, 'XRAY'),
                                    const SizedBox(width: 2),
                                    _buildModeButton(HandRenderMode.skeleton, 'SKELETON'),
                                    const SizedBox(width: 2),
                                    _buildModeButton(HandRenderMode.holographic, 'HOLOGRAPHIC'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141A17).withOpacity(0.92),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isLiveStreaming
                                    ? AdminTheme.lime.withOpacity(0.5)
                                    : const Color(0xFFF5A623).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              _isLiveStreaming ? 'STREAM: 25 HZ' : 'NO DEVICE',
                              style: TextStyle(
                                fontSize: 9,
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

              final telemetryPanel = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Repetition Ring Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RepetitionRingWidget(
                        completedReps: _currentRep,
                        targetReps: plan?.targetReps ?? _targetReps,
                        state: _repState,
                        elapsedText: elapsedStr,
                        size: isWidescreen ? 190 : 160,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Finger Flexion & Palmar Contact Card
                  FingerBarsWidget(
                    normalizedFlex: _liveFlex,
                    fsrContact: _isLiveStreaming ? _fsrContact : null,
                    targetRomMin: plan?.targetRomMin ?? 70.0,
                    targetRomMax: plan?.targetRomMax ?? 100.0,
                    isConnected: _isLiveStreaming,
                  ),
                ],
              );

              if (isWidescreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: handWidget,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: telemetryPanel,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  handWidget,
                  const SizedBox(height: 14),
                  telemetryPanel,
                ],
              );
            },
          ),
          const SizedBox(height: 60),
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
