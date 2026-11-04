import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/metric_stat_card.dart';
import '../widgets/clinical_flag_badge.dart';

class OverviewScreen extends StatelessWidget {
  final ApiService apiService;
  final ValueChanged<String> onSelectPatient;
  final VoidCallback onOpenLiveMonitor;

  const OverviewScreen({
    super.key,
    required this.apiService,
    required this.onSelectPatient,
    required this.onOpenLiveMonitor,
  });

  @override
  Widget build(BuildContext context) {
    final patients = apiService.patients;
    final flags = apiService.flags;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CLINICAL REHABILITATION OVERVIEW',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time supervisor monitor for neurological & hand motor rehabilitation.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AdminTheme.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onOpenLiveMonitor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.lime,
                  foregroundColor: AdminTheme.limeDark,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.sensors, size: 18),
                label: const Text(
                  'Open Live Cockpit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4 Top Metrics Cards
          Row(
            children: [
              MetricStatCard(
                title: 'Enrolled Cohort',
                value: '${patients.length}',
                subtitle: 'Active research patients',
                icon: Icons.people_outline,
                accentColor: AdminTheme.cyan,
              ),
              const SizedBox(width: 16),
              MetricStatCard(
                title: 'Active Streams',
                value: '1 LIVE',
                subtitle: 'Patient P-014 streaming @ 25Hz',
                icon: Icons.sensors,
                accentColor: AdminTheme.lime,
                onTap: onOpenLiveMonitor,
              ),
              const SizedBox(width: 16),
              const MetricStatCard(
                title: 'Cohort Adherence',
                value: '84.2%',
                subtitle: 'Target session completion',
                icon: Icons.check_circle_outline,
                accentColor: AdminTheme.green,
              ),
              const SizedBox(width: 16),
              MetricStatCard(
                title: 'Clinical Flags',
                value: '${flags.length}',
                subtitle: 'Fatigue & pain alerts',
                icon: Icons.warning_amber_rounded,
                accentColor: AdminTheme.amber,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Two-Column Grid: Patient Cohort List (Left) + Urgent Clinical Flags (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Active Cohort
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ENROLLED RESEARCH PATIENTS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${patients.length} PATIENTS',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AdminTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = patients[index];
                          final isLive = (p.pseudonym == 'P-014');
                          final plan = apiService.getPatientActivePlan(p.pseudonym);
                          final sessions = apiService.getPatientSessions(p.pseudonym);

                          return InkWell(
                            onTap: () => onSelectPatient(p.pseudonym),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AdminTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLive ? AdminTheme.lime.withOpacity(0.4) : AdminTheme.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isLive ? AdminTheme.lime.withOpacity(0.2) : const Color(0xFF1E2622),
                                    child: Text(
                                      p.pseudonym.replaceAll('-', ''),
                                      style: TextStyle(
                                        color: isLive ? AdminTheme.lime : AdminTheme.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Patient ${p.pseudonym}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AdminTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF161E1A),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${p.affectedHand.toUpperCase()} HAND',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: AdminTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                            if (isLive) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AdminTheme.lime.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'LIVE 25Hz',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: AdminTheme.lime,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.notes.isNotEmpty ? p.notes : 'General motor rehabilitation protocol',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF909B95),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Plan v${plan?.version ?? 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: AdminTheme.lime,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${sessions.length} sessions',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AdminTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: AdminTheme.textSecondary, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Right Column: Priority Movement Flags & Alerts
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MOVEMENT FLAGS & ALERTS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminTheme.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${flags.length} REVIEWS PENDING',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: flags.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final f = flags[index];
                          return ClinicalFlagBadge(
                            flag: f,
                            onTap: () => onSelectPatient(f.patientId),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
