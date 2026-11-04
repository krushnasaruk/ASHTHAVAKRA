import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class TaskProofMonitorScreen extends StatefulWidget {
  const TaskProofMonitorScreen({super.key});

  @override
  State<TaskProofMonitorScreen> createState() => _TaskProofMonitorScreenState();
}

class _TaskProofMonitorScreenState extends State<TaskProofMonitorScreen> {
  int _activeStateIndex = 3; // 0: Idle, 1: Waiting, 2: Grasped, 3: Lifted, 4: Transporting, 5: InZone, 6: Released
  bool _isJudgeView = false;
  bool _simulateOcclusion = false;

  final List<Map<String, dynamic>> _states = [
    {'name': 'IDLE', 'desc': 'Awaiting physical object placement'},
    {'name': 'WAITING_FOR_GRASP', 'desc': 'Hand approaching target block'},
    {'name': 'GRASPED', 'desc': 'FSR pressure exceeded contact threshold'},
    {'name': 'LIFTED', 'desc': 'Object cleared table surface (+50mm)'},
    {'name': 'TRANSPORTING', 'desc': 'Translating across workspace'},
    {'name': 'IN_TARGET_ZONE', 'desc': 'Aligned within ArUco target zone'},
    {'name': 'RELEASED', 'desc': 'Controlled release confirmed'},
  ];

  @override
  Widget build(BuildContext context) {
    final verdictState = _simulateOcclusion ? 'UNCERTAIN' : (_activeStateIndex == 6 ? 'SUCCESS' : 'IN_PROGRESS');
    final verdictColor = _simulateOcclusion ? AdminTheme.amber : (_activeStateIndex == 6 ? AdminTheme.green : AdminTheme.cyan);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    'TASKPROOF™ SENSOR FUSION VERIFICATION',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deterministic physical task verification combining glove FSR pressure, kinematics, & ArUco vision tracking.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AdminTheme.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View Switcher (Operator vs Judge)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeTab('OPERATOR DIAGNOSTIC', !_isJudgeView, () => setState(() => _isJudgeView = false)),
                          const SizedBox(width: 4),
                          _buildModeTab('JUDGE VERDICT', _isJudgeView, () => setState(() => _isJudgeView = true)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Occlusion Test Button
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _simulateOcclusion = !_simulateOcclusion);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _simulateOcclusion ? AdminTheme.amber : AdminTheme.textSecondary,
                        side: BorderSide(color: _simulateOcclusion ? AdminTheme.amber : AdminTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(_simulateOcclusion ? Icons.visibility_off : Icons.visibility, size: 16),
                      label: Text(_simulateOcclusion ? 'Marker Occluded (Active)' : 'Test Occlusion Guard'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // High-Impact Verdict Banner (Judge View feature)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: verdictColor.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: verdictColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: verdictColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _simulateOcclusion ? Icons.help_outline : (_activeStateIndex == 6 ? Icons.check_circle : Icons.sync),
                        color: verdictColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VERDICT: $verdictState',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: verdictColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _simulateOcclusion
                                ? 'HONESTY GUARD: Marker occluded.'
                                : 'State: ${_states[_activeStateIndex]['name']}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFC0CAC4)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: const Text(
                    'SHA-256 HASH VERIFIED',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AdminTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 7-State Horizontal Lifecycle Pipeline Tracker
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TASKPROOF 7-STATE PHYSICAL EXECUTION PIPELINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const Divider(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_states.length, (idx) {
                      final s = _states[idx];
                      final isPassed = idx < _activeStateIndex;
                      final isCurrent = idx == _activeStateIndex;

                      Color nodeColor = const Color(0xFF2E3832);
                      Color textColor = AdminTheme.textSecondary;
                      if (isPassed) {
                        nodeColor = AdminTheme.lime;
                        textColor = AdminTheme.lime;
                      } else if (isCurrent) {
                        nodeColor = AdminTheme.cyan;
                        textColor = AdminTheme.cyan;
                      }

                      return InkWell(
                        onTap: () => setState(() => _activeStateIndex = idx),
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCurrent ? nodeColor.withOpacity(0.15) : AdminTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isCurrent ? nodeColor : AdminTheme.borderSubtle),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isPassed ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                                        size: 14,
                                        color: nodeColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '0${idx + 1}',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s['name'] as String,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                ],
                              ),
                            ),
                            if (idx < _states.length - 1)
                              Container(
                                width: 18,
                                height: 2,
                                color: idx < _activeStateIndex ? AdminTheme.lime : const Color(0xFF2E3832),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Physical Guard Checklist Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final cards = [
                _buildGuardCard(
                  title: 'PALMAR CONTACT FORCE',
                  status: _activeStateIndex >= 2 ? 'PASS (1,840 ADC)' : 'PENDING',
                  desc: 'FSR contact pressure sustained >500ms',
                  isPassed: _activeStateIndex >= 2,
                  icon: Icons.compress,
                ),
                _buildGuardCard(
                  title: 'VERTICAL OBJECT LIFT',
                  status: _activeStateIndex >= 3 ? 'PASS (+62mm)' : 'PENDING',
                  desc: 'Cleared table boundary plane',
                  isPassed: _activeStateIndex >= 3,
                  icon: Icons.arrow_upward,
                ),
                _buildGuardCard(
                  title: 'ARUCO ZONE ALIGNMENT',
                  status: _simulateOcclusion ? 'FAIL (OCCLUSION)' : (_activeStateIndex >= 5 ? 'PASS (ZONE B)' : '25.0 Hz TRACKING'),
                  desc: 'Continuous optical centroid verification',
                  isPassed: !_simulateOcclusion && _activeStateIndex >= 5,
                  icon: Icons.center_focus_strong,
                ),
                _buildGuardCard(
                  title: 'TARGET RELEASE',
                  status: _activeStateIndex >= 6 ? 'CONFIRMED' : 'WAITING',
                  desc: 'Controlled release inside perimeter',
                  isPassed: _activeStateIndex >= 6,
                  icon: Icons.done_all,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 10),
                    cards[1],
                    const SizedBox(height: 10),
                    cards[2],
                    const SizedBox(height: 10),
                    cards[3],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[2]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[3]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AdminTheme.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: active ? AdminTheme.limeDark : AdminTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGuardCard({
    required String title,
    required String status,
    required String desc,
    required bool isPassed,
    required IconData icon,
  }) {
    final color = isPassed ? AdminTheme.green : AdminTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isPassed ? AdminTheme.lime : AdminTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8A9590)),
          ),
        ],
      ),
    );
  }
}
