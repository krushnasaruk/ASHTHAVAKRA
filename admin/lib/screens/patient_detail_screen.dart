import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/plan_editor_dialog.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final ApiService apiService;
  final VoidCallback onBack;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.apiService,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final patient = apiService.patients.firstWhere(
      (p) => p.pseudonym == patientId,
      orElse: () => apiService.patients.first,
    );
    final activePlan = apiService.getPatientActivePlan(patientId);
    final sessions = apiService.getPatientSessions(patientId);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button & Patient Header Row
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AdminTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: AdminTheme.lime.withOpacity(0.2),
                child: Text(
                  patient.pseudonym.replaceAll('-', ''),
                  style: const TextStyle(color: AdminTheme.lime, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PATIENT ${patient.pseudonym}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2622),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AdminTheme.border),
                        ),
                        child: Text(
                          '${patient.affectedHand.toUpperCase()} HAND PARESIS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient.notes.isNotEmpty ? patient.notes : 'Motor recovery protocol',
                    style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  PlanEditorDialog.show(
                    context,
                    patientId: patientId,
                    currentPlan: activePlan,
                    apiService: apiService,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.lime,
                  foregroundColor: AdminTheme.limeDark,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Modify Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Active Prescription Card (Observing mobile app plan schema)
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, color: AdminTheme.lime, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ACTIVE REHABILITATION PRESCRIPTION (VERSION ${activePlan?.version ?? 1})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'PRESCRIBED BY: ${activePlan?.setBy ?? "Clinical Lead"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlanPill('EXERCISE', (activePlan?.exerciseId ?? 'fist_clench').replaceAll('_', ' ').toUpperCase()),
                    _buildPlanPill('TARGET REPS', '${activePlan?.targetReps ?? 10} reps'),
                    _buildPlanPill('TARGET ROM', '${activePlan?.targetRomMin.toStringAsFixed(0)}% – ${activePlan?.targetRomMax.toStringAsFixed(0)}%'),
                    _buildPlanPill('HOLD / REST', '${activePlan?.holdS ?? 1.5}s / ${activePlan?.restS ?? 2.0}s'),
                    _buildPlanPill('SCHEDULE', '${activePlan?.sessionsPerWeek ?? 5} days/wk'),
                    _buildPlanPill('FATIGUE LIMIT', 'Drop >${activePlan?.fatigueDropThreshold.toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AdminTheme.amberMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminTheme.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AdminTheme.amber, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mandatory Safety Stop Directive: ${activePlan?.stopInstruction ?? "Stop if pain occurs"}',
                          style: const TextStyle(
                            color: Color(0xFFFFD38A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Historical Session Analytics Table
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'COMPLETED REHABILITATION SESSIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${sessions.length} SESSIONS RECORDED',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (sessions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: const Text('No sessions recorded yet for this patient.', style: TextStyle(color: AdminTheme.textSecondary)),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AdminTheme.surfaceElevated),
                      columns: const [
                        DataColumn(label: Text('DATE & TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('EXERCISE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('REPS (DONE/TARGET)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('MEAN ROM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('MAX ROM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('CONSISTENCY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('FATIGUE DROP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('QUALITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                      ],
                      rows: sessions.map((s) {
                        final isHighFatigue = (s.fatigueDropPct ?? 0) > (activePlan?.fatigueDropThreshold ?? 20.0);

                        return DataRow(
                          cells: [
                            DataCell(Text(dateFormat.format(s.startedAt), style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                            DataCell(Text(s.exerciseCode.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            DataCell(Text('${s.repsCompleted} / ${s.repsTarget}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.lime))),
                            DataCell(Text('${s.meanRom.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                            DataCell(Text('${s.maxRom.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                            DataCell(Text('${s.consistency?.toStringAsFixed(0) ?? 85}%', style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Row(
                                children: [
                                  Text('${s.fatigueDropPct?.toStringAsFixed(1) ?? 0.0}%', style: TextStyle(fontSize: 12, color: isHighFatigue ? AdminTheme.red : AdminTheme.textPrimary, fontWeight: isHighFatigue ? FontWeight.bold : FontWeight.normal)),
                                  if (isHighFatigue) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.warning, color: AdminTheme.red, size: 12),
                                  ],
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AdminTheme.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(s.dataQuality.toUpperCase(), style: const TextStyle(fontSize: 10, color: AdminTheme.green, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPill(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AdminTheme.textSecondary)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AdminTheme.lime)),
      ],
    );
  }
}
