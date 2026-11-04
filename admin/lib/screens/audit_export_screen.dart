import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/pdf_report_service.dart';
import '../theme/admin_theme.dart';

class AuditExportScreen extends StatefulWidget {
  final ApiService apiService;

  const AuditExportScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<AuditExportScreen> createState() => _AuditExportScreenState();
}

class _AuditExportScreenState extends State<AuditExportScreen> {
  bool _isGeneratingPdf = false;
  String _selectedPatientForExport = 'P-014';

  Future<void> _exportPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final patient = widget.apiService.patients.firstWhere(
        (p) => p.pseudonym == _selectedPatientForExport,
        orElse: () => widget.apiService.patients.first,
      );
      final sessions = widget.apiService.getPatientSessions(_selectedPatientForExport);
      final activePlan = widget.apiService.getPatientActivePlan(_selectedPatientForExport);
      final flags = widget.apiService.flags.where((f) => f.patientId == _selectedPatientForExport).toList();

      final pdfBytes = await PdfReportService.generateSummaryReport(
        patient: patient,
        plan: activePlan,
        sessions: sessions,
        flags: flags,
      );

      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'H10_Clinical_Report_$_selectedPatientForExport.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: AdminTheme.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _downloadCsv() {
    final sessions = widget.apiService.getPatientSessions(_selectedPatientForExport);
    final buf = StringBuffer();
    buf.writeln('session_id,patient_id,exercise,started_at,duration_s,reps_done,reps_target,mean_rom,max_rom,fatigue_drop,quality');
    for (final s in sessions) {
      buf.writeln('${s.id},${s.patientId},${s.exerciseCode},${s.startedAt.toIso8601String()},${s.durationS},${s.repsCompleted},${s.repsTarget},${s.meanRom},${s.maxRom},${s.fatigueDropPct ?? 0},${s.dataQuality}');
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.surface,
        title: Text('CSV Telemetry for Patient $_selectedPatientForExport', style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              buf.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AdminTheme.lime),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: AdminTheme.lime))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditLogs = widget.apiService.auditLog;
    final patients = widget.apiService.patients;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

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
                    'CLINICAL AUDIT LOG & DATA EXPORT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Immutable prescription tracking, version history, and regulatory reporting suite.',
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
                  DropdownButton<String>(
                    value: _selectedPatientForExport,
                    dropdownColor: AdminTheme.surfaceElevated,
                    style: const TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    items: patients.map((p) => DropdownMenuItem(value: p.pseudonym, child: Text('Patient ${p.pseudonym}'))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPatientForExport = val);
                    },
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _exportPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.lime,
                      foregroundColor: AdminTheme.limeDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isGeneratingPdf
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Generate 1-Page Summary PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _downloadCsv,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.cyan,
                      side: const BorderSide(color: AdminTheme.cyan),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download CSV Telemetry'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Immutable Audit Log Table
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
                      'PRESCRIPTION MODIFICATION & EVENT AUDIT TRAIL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${auditLogs.length} LOG ENTRIES',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (auditLogs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: const Text(
                      'No manual prescription modifications logged yet. All modifications generate cryptographic audit trails.',
                      style: TextStyle(color: AdminTheme.textSecondary),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AdminTheme.surfaceElevated),
                      columns: const [
                        DataColumn(label: Text('TIMESTAMP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('PATIENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('NEW VERSION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('CLINICIAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                        DataColumn(label: Text('CLINICAL JUSTIFICATION / REASON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AdminTheme.textSecondary))),
                      ],
                      rows: auditLogs.map((log) {
                        return DataRow(
                          cells: [
                            DataCell(Text(dateFormat.format(DateTime.parse(log['timestamp'] as String)), style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AdminTheme.lime.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text((log['action'] as String).replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.lime)),
                              ),
                            ),
                            DataCell(Text(log['patient_id'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            DataCell(Text('v${log['version']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.cyan))),
                            DataCell(Text(log['clinician_id'] as String, style: const TextStyle(fontSize: 12))),
                            DataCell(Text(log['reason'] as String, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
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
}
