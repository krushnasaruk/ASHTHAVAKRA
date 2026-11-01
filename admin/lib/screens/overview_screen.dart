import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/api_service.dart';

class OverviewScreen extends StatelessWidget {
  final ApiService apiService;
  final Function(String patientId) onSelectPatient;

  const OverviewScreen({
    super.key,
    required this.apiService,
    required this.onSelectPatient,
  });

  void _showAcknowledgeDialog(BuildContext context, ClinicalFlag flag) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Acknowledge Flag: ${flag.type}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${flag.patientId}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(flag.message),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Clinician Review Notes',
                hintText: 'e.g., Reviewed with patient; reduced reps to 10.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              apiService.acknowledgeFlag(
                flagId: flag.id,
                note: noteController.text.trim().isEmpty ? 'Reviewed by clinician.' : noteController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save Acknowledgment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patients = apiService.patients;
    final flags = apiService.flags;
    final openFlags = flags.where((f) => !f.isAcknowledged).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Clinical Rehabilitation Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Live monitoring statistics and priority review alerts across all enrolled research participants.',
            style: TextStyle(fontSize: 13, color: Color(H10Tokens.colorSecondaryText)),
          ),
          const SizedBox(height: 20),

          // 4 Metric Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final cards = [
                _buildMetricCard(
                  title: 'ACTIVE PATIENTS',
                  value: '${patients.length}',
                  subtitle: 'Enrolled in study',
                  icon: Icons.people_outline,
                  color: const Color(H10Tokens.colorPrimary),
                ),
                _buildMetricCard(
                  title: 'OPEN CLINICAL FLAGS',
                  value: '${openFlags.length}',
                  subtitle: openFlags.isEmpty ? 'All cleared' : 'Requires review',
                  icon: Icons.warning_amber_rounded,
                  color: openFlags.isEmpty ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorWarning),
                  isAlert: openFlags.isNotEmpty,
                ),
                _buildMetricCard(
                  title: 'SESSIONS TODAY',
                  value: '3',
                  subtitle: 'Target: 5 sessions',
                  icon: Icons.fitness_center_outlined,
                  color: const Color(H10Tokens.colorInfo),
                ),
                _buildMetricCard(
                  title: '7-DAY ADHERENCE',
                  value: '84.0%',
                  subtitle: 'Overall clinic average',
                  icon: Icons.show_chart,
                  color: const Color(H10Tokens.colorSuccess),
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: c))).toList(),
                );
              } else {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 20) / 2, child: c)).toList(),
                );
              }
            },
          ),
          const SizedBox(height: 28),

          // Priority Flags Feed
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 20, color: Color(H10Tokens.colorWarning)),
                          const SizedBox(width: 8),
                          const Text(
                            'Priority Movement Flags & Alerts',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: openFlags.isNotEmpty ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${openFlags.length} Open',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: openFlags.isNotEmpty ? const Color(H10Tokens.colorWarning) : const Color(H10Tokens.colorSuccess),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (openFlags.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 40, color: Color(H10Tokens.colorSuccess)),
                          SizedBox(height: 8),
                          Text('No active flags. All movements within prescribed safety tolerances.', style: TextStyle(color: Color(H10Tokens.colorSecondaryText))),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: openFlags.length,
                      separatorBuilder: (_, __) => const Divider(height: 20, color: Color(H10Tokens.colorBorder)),
                      itemBuilder: (context, index) {
                        final flag = openFlags[index];
                        final isAlert = flag.severity == 'review';
                        final sevColor = isAlert ? const Color(H10Tokens.colorWarning) : const Color(H10Tokens.colorInfo);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sevColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                flag.severity.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sevColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => onSelectPatient(flag.patientId),
                                        child: Text(
                                          flag.patientId,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary), decoration: TextDecoration.underline),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('• ${flag.type}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      Text(
                                        flag.createdAt.toIso8601String().substring(0, 16).replaceAll('T', ' '),
                                        style: const TextStyle(fontSize: 11, color: Color(H10Tokens.colorSecondaryText)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(flag.message, style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.check, size: 14),
                              label: const Text('Acknowledge'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _showAcknowledgeDialog(context, flag),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isAlert = false,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
        side: BorderSide(color: isAlert ? const Color(H10Tokens.colorWarning) : const Color(H10Tokens.colorBorder), width: isAlert ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(H10Tokens.colorSecondaryText)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(H10Tokens.colorSecondaryText)),
            ),
          ],
        ),
      ),
    );
  }
}
