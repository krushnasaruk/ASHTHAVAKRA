import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/live_telemetry_card.dart';
import '../widgets/web_hand_viewer.dart';

class LiveMonitorScreen extends StatefulWidget {
  final ApiService apiService;
  final String initialPatientId;

  const LiveMonitorScreen({
    super.key,
    required this.apiService,
    this.initialPatientId = 'P-014',
  });

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  late String _selectedPatient;
  bool _isLiveStreaming = true;
  Timer? _telemetryTimer;

  double _phase = 0.0;
  List<double> _liveFlex = [0.0, 0.0, 0.0, 0.0, 0.0];
  double _liveFsr = 0.0;
  final int _currentRep = 3;
  final int _targetReps = 12;
  String _repState = 'WAITING';

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatientId;
    _startSimulatedStream();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  void _startSimulatedStream() {
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_isLiveStreaming || !mounted) return;

      setState(() {
        _phase += 0.06;
        final wave = (math.sin(_phase) * 0.5 + 0.5).clamp(0.0, 1.0);

        // State detection based on wave cycle
        if (wave < 0.15) {
          _repState = 'WAITING';
        } else if (wave < 0.70 && math.cos(_phase) > 0) {
          _repState = 'FLEXING';
        } else if (wave >= 0.70) {
          _repState = 'HOLDING';
        } else {
          _repState = 'EXTENDING';
        }

        final midCurl = wave * 82.0;
        _liveFlex = [
          wave * 72.0,                  // Thumb
          wave * 86.0,                  // Index
          midCurl,                      // Middle
          (midCurl * 0.90).clamp(0, 100), // Ring (est)
          (midCurl * 0.75).clamp(0, 100), // Pinky (est)
        ];

        _liveFsr = wave > 0.65 ? (wave * 78.0) : 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final patients = widget.apiService.patients;
    final plan = widget.apiService.getPatientActivePlan(_selectedPatient);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE CLINIC TELEMETRY COCKPIT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time supervisor tele-rehabilitation stream @ 25 Hz with biomechanical kinematics.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AdminTheme.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Patient Selector Dropdown Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPatient,
                        dropdownColor: AdminTheme.surfaceElevated,
                        icon: const Icon(Icons.arrow_drop_down, color: AdminTheme.lime),
                        style: const TextStyle(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        items: patients.map((p) {
                          return DropdownMenuItem(
                            value: p.pseudonym,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Patient ${p.pseudonym}'),
                                const SizedBox(width: 6),
                                Text('(${p.affectedHand})', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPatient = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stream Toggle
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isLiveStreaming = !_isLiveStreaming);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLiveStreaming ? const Color(0xFF1E2822) : AdminTheme.lime,
                      foregroundColor: _isLiveStreaming ? AdminTheme.lime : AdminTheme.limeDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: _isLiveStreaming ? AdminTheme.lime : Colors.transparent),
                    ),
                    icon: Icon(_isLiveStreaming ? Icons.pause : Icons.play_arrow, size: 16),
                    label: Text(_isLiveStreaming ? 'Pause Stream' : 'Resume Stream', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Prescription Meta Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AdminTheme.lime, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      'ACTIVE PROTOCOL: ${(plan?.exerciseId ?? "FIST_CLENCH").replaceAll("_", " ").toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminTheme.lime.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PLAN v${plan?.version ?? 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AdminTheme.lime,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'SAFETY: ${plan?.stopInstruction ?? "Stop if pain occurs"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminTheme.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Live Monitor Stage: 3D Hand Model (Left) + 5-Channel Telemetry (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: 3D Biomechanical Hand Kinematic Stage
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    WebHandViewer(
                      normalizedFlex: _liveFlex,
                      height: 380,
                      isStreaming: _isLiveStreaming,
                    ),
                    const SizedBox(height: 16),
                    // Quick Kinematic Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat('PEAK ROM', '${_liveFlex[1].toStringAsFixed(0)}%', AdminTheme.lime),
                          _buildMiniStat('HOLD DURATION', '${plan?.holdS ?? 1.5}s', AdminTheme.cyan),
                          _buildMiniStat('FSR FORCE', '${_liveFsr.toStringAsFixed(0)}%', AdminTheme.amber),
                          _buildMiniStat('QUALITY', 'OPTIMAL', AdminTheme.green),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right: Live Telemetry Bars & Rep Progress
              Expanded(
                flex: 6,
                child: LiveTelemetryCard(
                  normalizedFlex: _liveFlex,
                  fsrContact: _liveFsr,
                  targetRomMin: plan?.targetRomMin ?? 70.0,
                  targetRomMax: plan?.targetRomMax ?? 100.0,
                  packetRateHz: 25.0,
                  currentRep: _currentRep,
                  targetReps: plan?.targetReps ?? _targetReps,
                  exerciseState: _repState,
                  isStreaming: _isLiveStreaming,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
