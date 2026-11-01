import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/api_service.dart';
import '../services/pdf_report_service.dart';

class PatientDetailScreen extends StatefulWidget {
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
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPlanEditorDialog(BuildContext context, RehabilitationPlan? currentPlan) {
    final repsController = TextEditingController(text: currentPlan?.targetReps.toString() ?? '10');
    final romMinController = TextEditingController(text: currentPlan?.targetRomMin.toStringAsFixed(0) ?? '70');
    final romMaxController = TextEditingController(text: currentPlan?.targetRomMax.toStringAsFixed(0) ?? '100');
    final holdController = TextEditingController(text: currentPlan?.holdS.toString() ?? '0.5');
    final restController = TextEditingController(text: currentPlan?.restS.toString() ?? '2.0');
    final reasonController = TextEditingController();
    String selectedExercise = currentPlan?.exerciseId ?? 'fist_clench';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Plan for ${widget.patientId} (Creates v${(currentPlan?.version ?? 1) + 1})'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedExercise,
                  decoration: const InputDecoration(labelText: 'Prescribed Exercise'),
                  items: const [
                    DropdownMenuItem(value: 'fist_clench', child: Text('Fist Clench & Release')),
                    DropdownMenuItem(value: 'finger_tap', child: Text('Single-Finger Tapping')),
                    DropdownMenuItem(value: 'pinch', child: Text('Thumb-Index Pinch')),
                    DropdownMenuItem(value: 'wrist_rotation', child: Text('Forearm Rotation')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedExercise = val;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        decoration: const InputDecoration(labelText: 'Target Reps'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: holdController,
                        decoration: const InputDecoration(labelText: 'Hold Time (s)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: restController,
                        decoration: const InputDecoration(labelText: 'Rest (s)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: romMinController,
                        decoration: const InputDecoration(labelText: 'ROM Min (%)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: romMaxController,
                        decoration: const InputDecoration(labelText: 'ROM Max (%)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Justification for Plan Modification *',
                    hintText: 'e.g., Progressed target ROM by 5% due to improved active flexion.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a clinical justification for the plan update.')),
                );
                return;
              }

              widget.apiService.updatePlan(
                patientId: widget.patientId,
                exerciseId: selectedExercise,
                targetReps: int.tryParse(repsController.text) ?? 10,
                targetRomMin: double.tryParse(romMinController.text) ?? 70.0,
                targetRomMax: double.tryParse(romMaxController.text) ?? 100.0,
                holdS: double.tryParse(holdController.text) ?? 0.5,
                restS: double.tryParse(restController.text) ?? 2.0,
                sessionsPerWeek: currentPlan?.sessionsPerWeek ?? 5,
                stopInstruction: currentPlan?.stopInstruction ?? 'Stop if sharp pain.',
                fatigueDropThreshold: currentPlan?.fatigueDropThreshold ?? 20.0,
                clinicianReason: reason,
              );

              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan updated and versioned successfully!')),
              );
            },
            child: const Text('Save New Plan Version'),
          ),
        ],
      ),
    );
  }

  void _showAcknowledgeDialog(BuildContext context, ClinicalFlag flag) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Acknowledge: ${flag.type}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(flag.message),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Clinician Review Notes',
                hintText: 'e.g. Consulted patient; adjusted hold interval.',
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
              widget.apiService.acknowledgeFlag(
                flagId: flag.id,
                note: noteController.text.trim().isEmpty ? 'Reviewed by clinician.' : noteController.text.trim(),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.apiService.patients.firstWhere(
      (p) => p.pseudonym == widget.patientId || p.id == widget.patientId,
      orElse: () => widget.apiService.patients.first,
    );
    final sessions = widget.apiService.getPatientSessions(widget.patientId);
    final activePlan = widget.apiService.getPatientActivePlan(widget.patientId);
    final flags = widget.apiService.flags.where((f) => f.patientId == widget.patientId).toList();
    final hasSimulated = sessions.any((s) => s.dataSource == 'simulated');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Back & Patient Header Card
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Patient List',
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'Patient ${patient.pseudonym}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(H10Tokens.colorSurfaceTint).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${patient.affectedHand.toUpperCase()} HAND',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              if (hasSimulated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    'INCLUDES SIMULATED DATA',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF Summary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(H10Tokens.colorPrimary),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  PdfReportService.printOrDownloadReport(
                    patient: patient,
                    plan: activePlan,
                    sessions: sessions,
                    flags: flags,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Goal & Baseline Summary Strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(H10Tokens.colorBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Goal: ${patient.notes.isNotEmpty ? patient.notes : "Active motor recovery"}',
                    style: const TextStyle(fontSize: 13, color: Color(H10Tokens.colorText)),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Baseline Fist: 72.5%  |  Baseline Pinch: 65.0%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorSecondaryText)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(H10Tokens.colorPrimary),
            unselectedLabelColor: const Color(H10Tokens.colorSecondaryText),
            indicatorColor: const Color(H10Tokens.colorPrimary),
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.history, size: 18), text: 'Sessions'),
              Tab(icon: Icon(Icons.show_chart, size: 18), text: 'Progress & Trends'),
              Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Rehabilitation Plan'),
              Tab(icon: Icon(Icons.flag_outlined, size: 18), text: 'Flags & Alerts'),
              Tab(icon: Icon(Icons.download, size: 18), text: 'Export & Raw Data'),
            ],
          ),
          const SizedBox(height: 12),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Sessions Tab
                _buildSessionsTab(sessions),

                // 2. Progress & Trends Tab
                _buildProgressTab(patient, sessions),

                // 3. Plan Editor Tab
                _buildPlanTab(activePlan),

                // 4. Flags Tab
                _buildFlagsTab(flags),

                // 5. Export Tab
                _buildExportTab(patient, sessions, flags, activePlan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab(List<SessionRecord> sessions) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No sessions recorded for this patient.'));
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
        side: const BorderSide(color: Color(H10Tokens.colorBorder)),
      ),
      child: ListView.separated(
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(H10Tokens.colorBorder)),
        itemBuilder: (context, index) {
          final s = sessions[index];
          final isSim = s.dataSource == 'simulated';

          return ExpansionTile(
            title: Row(
              children: [
                Text(
                  s.exerciseCode.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
                if (isSim)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(3)),
                    child: const Text('SIMULATED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                  ),
                const Spacer(),
                Text(
                  s.startedAt.toIso8601String().substring(0, 16).replaceAll('T', ' '),
                  style: const TextStyle(fontSize: 12, color: Color(H10Tokens.colorSecondaryText)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Text('Reps: ${s.repsCompleted}/${s.repsTarget} • Mean ROM: ${s.meanRom.toStringAsFixed(1)}% • Quality: ${s.dataQuality.toUpperCase()}'),
                  if (s.fatigueDropPct != null)
                    Text(' • Fatigue Drop: ${s.fatigueDropPct!.toStringAsFixed(1)}%', style: TextStyle(color: s.fatigueDropPct! > 20.0 ? const Color(H10Tokens.colorError) : const Color(H10Tokens.colorSecondaryText))),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clinical Note: ${s.note.isNotEmpty ? s.note : "None recorded"}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Pain Rating: ${s.painAfter}/10', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        Text('Fatigue Rating: ${s.fatigueAfter}/10', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        Text('Consistency: ${s.consistency != null ? "${s.consistency!.toStringAsFixed(0)}%" : "N/A"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressTab(Patient patient, List<SessionRecord> sessions) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  const Text('Active ROM Progression', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Tracking mean active range of motion achieved per rehabilitation session.', style: TextStyle(fontSize: 12, color: Color(H10Tokens.colorSecondaryText))),
                  const SizedBox(height: 16),
                  // Visual ROM bars
                  Column(
                    children: sessions.map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            SizedBox(width: 90, child: Text(s.startedAt.toIso8601String().substring(5, 10), style: const TextStyle(fontSize: 12))),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (s.meanRom / 100.0).clamp(0.0, 1.0),
                                  minHeight: 18,
                                  backgroundColor: const Color(H10Tokens.colorBorder),
                                  color: const Color(H10Tokens.colorPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(width: 50, child: Text('${s.meanRom.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Finger mobility palette bars
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
                  const Text('Finger Mobility Distribution (Okabe-Ito Palette)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (i) {
                      final name = H10Tokens.fingerNames[i];
                      final color = Color(H10Tokens.fingerColors[i]);
                      final rom = [75.0, 82.0, 78.0, 68.0, 60.0][i];

                      return Column(
                        children: [
                          Container(
                            width: 24,
                            height: 100,
                            alignment: Alignment.bottomCenter,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Container(
                              width: 24,
                              height: rom,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('${rom.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Color(H10Tokens.colorSecondaryText))),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab(RehabilitationPlan? plan) {
    final history = widget.apiService.getPatientPlanHistory(widget.patientId);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Prescription (Version ${plan?.version ?? 1})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Prescribed on: ${plan?.validFrom.toIso8601String().substring(0, 10) ?? "Initial"}', style: const TextStyle(fontSize: 12, color: Color(H10Tokens.colorSecondaryText))),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Update / Version Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(H10Tokens.colorPrimary),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showPlanEditorDialog(context, plan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _planItem('Exercise', plan?.exerciseId.replaceAll('_', ' ').toUpperCase() ?? 'FIST CLENCH'),
                      _planItem('Target Repetitions', '${plan?.targetReps ?? 10} reps'),
                      _planItem('ROM Target Band', '${plan?.targetRomMin.toStringAsFixed(0) ?? 70}–${plan?.targetRomMax.toStringAsFixed(0) ?? 100}%'),
                      _planItem('Hold Duration', '${plan?.holdS ?? 0.5}s'),
                      _planItem('Rest Between Reps', '${plan?.restS ?? 2.0}s'),
                      _planItem('Frequency', '${plan?.sessionsPerWeek ?? 5} sessions / week'),
                      _planItem('Fatigue Alert Threshold', '${plan?.fatigueDropThreshold ?? 20.0}% drop'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Clinical Stop Instruction: ${plan?.stopInstruction ?? "None"}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Version history
          if (history.length > 1) ...[
            const Text('Plan Version History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                side: const BorderSide(color: Color(H10Tokens.colorBorder)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = history[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: i == 0 ? const Color(H10Tokens.colorPrimary) : const Color(H10Tokens.colorSecondaryText),
                      foregroundColor: Colors.white,
                      child: Text('v${p.version}'),
                    ),
                    title: Text('${p.exerciseId} • ${p.targetReps} reps • ${p.targetRomMin.toStringAsFixed(0)}-${p.targetRomMax.toStringAsFixed(0)}% ROM'),
                    subtitle: Text('Created: ${p.validFrom.toIso8601String().substring(0, 10)} ${i == 0 ? "(ACTIVE)" : "(ARCHIVED)"}'),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(H10Tokens.colorSecondaryText))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFlagsTab(List<ClinicalFlag> flags) {
    if (flags.isEmpty) {
      return const Center(child: Text('No clinical flags recorded for this patient.'));
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
        side: const BorderSide(color: Color(H10Tokens.colorBorder)),
      ),
      child: ListView.separated(
        itemCount: flags.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(H10Tokens.colorBorder)),
        itemBuilder: (context, index) {
          final flag = flags[index];
          final isAlert = flag.severity == 'review';
          final sevColor = isAlert ? const Color(H10Tokens.colorWarning) : const Color(H10Tokens.colorInfo);

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: sevColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(flag.severity.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sevColor)),
            ),
            title: Text('${flag.type}: ${flag.message}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (flag.isAcknowledged)
                  Text('Acknowledged by ${flag.acknowledgedBy}: "${flag.ackNote ?? "Reviewed"}"', style: const TextStyle(fontSize: 11, color: Color(H10Tokens.colorSuccess))),
              ],
            ),
            trailing: flag.isAcknowledged
                ? const Icon(Icons.check_circle, color: Color(H10Tokens.colorSuccess), size: 18)
                : OutlinedButton(
                    onPressed: () => _showAcknowledgeDialog(context, flag),
                    child: const Text('Acknowledge'),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildExportTab(Patient patient, List<SessionRecord> sessions, List<ClinicalFlag> flags, RehabilitationPlan? plan) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
        side: const BorderSide(color: Color(H10Tokens.colorBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clinical Reporting & Data Export', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Generate validated clinical summary PDFs for multidisciplinary team review, or download raw telemetry CSV files.',
              style: TextStyle(fontSize: 13, color: Color(H10Tokens.colorSecondaryText)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate 1-Page Summary PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(H10Tokens.colorPrimary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: () {
                    PdfReportService.printOrDownloadReport(
                      patient: patient,
                      plan: plan,
                      sessions: sessions,
                      flags: flags,
                    );
                  },
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download Telemetry CSV'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: () {
                    final csv = widget.apiService.exportCsv(widget.patientId);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('CSV Telemetry Export: ${widget.patientId}'),
                        content: SizedBox(
                          width: 600,
                          height: 300,
                          child: SingleChildScrollView(
                            child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All generated exports contain mandatory research prototype disclaimers. Data is pseudonymized and contains no direct patient identifiers.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
