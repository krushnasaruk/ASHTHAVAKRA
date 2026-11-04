import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/vector_icons.dart';
import '../widgets/clinical_flag_badge.dart';

class OverviewScreen extends StatelessWidget {
  final ApiService apiService;
  final ValueChanged<String> onSelectPatient;
  final VoidCallback onOpenLiveMonitor;
  final VoidCallback onOpenTaskProof;

  const OverviewScreen({
    super.key,
    required this.apiService,
    required this.onSelectPatient,
    required this.onOpenLiveMonitor,
    required this.onOpenTaskProof,
  });

  @override
  Widget build(BuildContext context) {
    final patients = apiService.patients;
    final flags = apiService.flags;
    final defaultPlan = apiService.getPatientActivePlan('P-014');
    final p014Sessions = apiService.getPatientSessions('P-014');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWidescreen = constraints.maxWidth >= 850;

        // 1. Master Telemetry Hero Card
        final telemetryHeroCard = InkWell(
          onTap: onOpenLiveMonitor,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF121715),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0xFF232D28), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'ASHTAVAKRA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.auto_awesome,
                          color: AdminTheme.lime,
                          size: 13,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AdminTheme.lime,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi, color: Color(0xFF121715), size: 11),
                          SizedBox(width: 3),
                          Text(
                            '3-CH LIVE',
                            style: TextStyle(
                              color: Color(0xFF121715),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'TELEMETRY STREAM',
                  style: TextStyle(
                    color: Color(0xFF7A837E),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Text(
                      '921,600',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'BAUD',
                      style: TextStyle(
                        color: AdminTheme.lime,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'ESP32-S3 N16R8 • 16-BIT ADS1115',
                  style: TextStyle(
                    color: Color(0xFFA0AAB0),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROFILE',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'demo3 (3-CH Measured, 2-CH Est.)',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'POWER',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.usb, color: AdminTheme.lime, size: 13),
                              SizedBox(width: 3),
                              Text(
                                'USB-C 5.0V',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        // 2. Prescribed Plan Card
        final prescriptionCard = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF121715),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF222B26), width: 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AdminTheme.lime,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRESCRIPTION',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B0F0E),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Target: ${defaultPlan?.targetReps ?? 10} reps',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A221E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: VectorIcon.routines(size: 20, color: AdminTheme.lime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (defaultPlan?.exerciseId ?? 'fist_clench').replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Patient P-014 • Right Hand Paresis',
                          style: TextStyle(
                            fontSize: 11,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${p014Sessions.length} / ${defaultPlan?.sessionsPerWeek ?? 5}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'sessions completed this week',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AdminTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (p014Sessions.length / (defaultPlan?.sessionsPerWeek ?? 5)).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF1A221E),
                  color: AdminTheme.lime,
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: onOpenLiveMonitor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.lime,
                    foregroundColor: const Color(0xFF0B0F0E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Launch Real-Time Live HUD',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        // 3. Four Squircle Quick Action Buttons
        final quickActionsRow = Row(
          children: [
            _buildSquircleAction(
              iconWidget: const VectorIcon.taskProof(size: 18, color: AdminTheme.lime),
              label: 'TaskProof™',
              onTap: onOpenTaskProof,
            ),
            const SizedBox(width: 8),
            _buildSquircleAction(
              iconWidget: const VectorIcon.judge(size: 18, color: AdminTheme.cyan),
              label: 'Judge View',
              onTap: onOpenTaskProof,
            ),
            const SizedBox(width: 8),
            _buildSquircleAction(
              iconWidget: const VectorIcon.routines(size: 18, color: AdminTheme.amber),
              label: 'Live Stream',
              onTap: onOpenLiveMonitor,
            ),
            const SizedBox(width: 8),
            _buildSquircleAction(
              iconWidget: const VectorIcon.preflight(size: 18, color: Color(0xFF009E73)),
              label: 'Preflight',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preflight Check: BLE Online, ADS1115 Calibrated (16-bit), IMU Quaternion Locked.'),
                    backgroundColor: Color(0xFF141A17),
                  ),
                );
              },
            ),
          ],
        );

        // 4. Enrolled Cohort List
        final cohortListWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ENROLLED COHORT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AdminTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = patients[index];
                final isLive = (p.pseudonym == 'P-014');
                final plan = apiService.getPatientActivePlan(p.pseudonym);

                return InkWell(
                  onTap: () => onSelectPatient(p.pseudonym),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121715),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLive ? AdminTheme.lime.withOpacity(0.3) : const Color(0xFF222B26),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: isLive ? AdminTheme.lime.withOpacity(0.2) : const Color(0xFF1A221E),
                          child: Text(
                            p.pseudonym.replaceAll('-', ''),
                            style: TextStyle(
                              color: isLive ? AdminTheme.lime : AdminTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      'Patient ${p.pseudonym}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AdminTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161E1A),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${p.affectedHand.toUpperCase()} HAND',
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: AdminTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    if (isLive) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AdminTheme.lime.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: AdminTheme.lime,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Target: ${plan?.targetRomMin.toInt()}%+ ROM • ${(plan?.exerciseId ?? "fist_clench").replaceAll("_", " ")}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AdminTheme.textSecondary, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );

        // 5. Clinical Safety & Fatigue Flags Feed
        final flagsWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACTIVE CLINICAL FLAGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AdminTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            if (flags.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121715),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF222B26)),
                ),
                child: const Center(
                  child: Text(
                    'No active clinical flags. All patient sessions within safe bounds.',
                    style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                  ),
                ),
              )
            else
              ...flags.take(4).map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClinicalFlagBadge(flag: f),
                    ),
                  ),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWidescreen) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: telemetryHeroCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: prescriptionCard),
                  ],
                ),
                const SizedBox(height: 16),
                quickActionsRow,
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: cohortListWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: flagsWidget),
                  ],
                ),
              ] else ...[
                telemetryHeroCard,
                const SizedBox(height: 16),
                quickActionsRow,
                const SizedBox(height: 18),
                prescriptionCard,
                const SizedBox(height: 20),
                cohortListWidget,
                const SizedBox(height: 20),
                flagsWidget,
              ],
              const SizedBox(height: 70),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquircleAction({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF121715),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222B26), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF161E1A),
                  shape: BoxShape.circle,
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
