import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';

class PlanEditorDialog extends StatefulWidget {
  final String patientId;
  final RehabilitationPlan? currentPlan;
  final ApiService apiService;

  const PlanEditorDialog({
    super.key,
    required this.patientId,
    required this.currentPlan,
    required this.apiService,
  });

  static Future<void> show(
    BuildContext context, {
    required String patientId,
    required RehabilitationPlan? currentPlan,
    required ApiService apiService,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PlanEditorDialog(
        patientId: patientId,
        currentPlan: currentPlan,
        apiService: apiService,
      ),
    );
  }

  @override
  State<PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<PlanEditorDialog> {
  late int _targetReps;
  late double _targetRomMin;
  late double _targetRomMax;
  late double _holdS;
  late double _restS;
  late int _sessionsPerWeek;
  late double _fatigueDropThreshold;
  late TextEditingController _stopInstructionCtrl;
  late TextEditingController _reasonCtrl;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.currentPlan;
    _targetReps = p?.targetReps ?? 10;
    _targetRomMin = p?.targetRomMin ?? 70.0;
    _targetRomMax = p?.targetRomMax ?? 100.0;
    _holdS = p?.holdS ?? 1.5;
    _restS = p?.restS ?? 2.0;
    _sessionsPerWeek = p?.sessionsPerWeek ?? 5;
    _fatigueDropThreshold = p?.fatigueDropThreshold ?? 20.0;
    _stopInstructionCtrl = TextEditingController(
      text: p?.stopInstruction ?? 'Stop if you feel sharp pain. Rest as needed.',
    );
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _stopInstructionCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _savePlan() {
    if (!_formKey.currentState!.validate()) return;

    widget.apiService.updatePlan(
      patientId: widget.patientId,
      exerciseId: widget.currentPlan?.exerciseId ?? 'fist_clench',
      targetReps: _targetReps,
      targetRomMin: _targetRomMin,
      targetRomMax: _targetRomMax,
      holdS: _holdS,
      restS: _restS,
      sessionsPerWeek: _sessionsPerWeek,
      stopInstruction: _stopInstructionCtrl.text.trim(),
      fatigueDropThreshold: _fatigueDropThreshold,
      clinicianReason: _reasonCtrl.text.trim(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prescription updated for Patient ${widget.patientId} (New Version Active)'),
        backgroundColor: AdminTheme.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextVersion = (widget.currentPlan?.version ?? 0) + 1;

    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminTheme.border, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UPDATE PRESCRIPTION — PATIENT ${widget.patientId}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AdminTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Will generate Version $nextVersion with immutable audit trail',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AdminTheme.textSecondary, size: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // Target Repetitions & Sessions Per Week
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'TARGET REPETITIONS',
                          value: _targetReps.toString(),
                          onChanged: (v) => _targetReps = int.tryParse(v) ?? _targetReps,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildNumberField(
                          label: 'SESSIONS / WEEK',
                          value: _sessionsPerWeek.toString(),
                          onChanged: (v) => _sessionsPerWeek = int.tryParse(v) ?? _sessionsPerWeek,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Target ROM Range (Min - Max)
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'TARGET MIN ROM (%)',
                          value: _targetRomMin.toStringAsFixed(0),
                          onChanged: (v) => _targetRomMin = double.tryParse(v) ?? _targetRomMin,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildNumberField(
                          label: 'TARGET MAX ROM (%)',
                          value: _targetRomMax.toStringAsFixed(0),
                          onChanged: (v) => _targetRomMax = double.tryParse(v) ?? _targetRomMax,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hold & Rest Durations
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'PEAK HOLD (SEC)',
                          value: _holdS.toStringAsFixed(1),
                          onChanged: (v) => _holdS = double.tryParse(v) ?? _holdS,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildNumberField(
                          label: 'REST PAUSE (SEC)',
                          value: _restS.toStringAsFixed(1),
                          onChanged: (v) => _restS = double.tryParse(v) ?? _restS,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildNumberField(
                          label: 'FATIGUE DROP (%)',
                          value: _fatigueDropThreshold.toStringAsFixed(0),
                          onChanged: (v) => _fatigueDropThreshold = double.tryParse(v) ?? _fatigueDropThreshold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stop Instruction text
                  const Text(
                    'PATIENT SAFETY & STOP INSTRUCTION',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _stopInstructionCtrl,
                    style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AdminTheme.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AdminTheme.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mandatory Clinician Justification
                  const Text(
                    'CLINICAL JUSTIFICATION FOR PLAN MODIFICATION *',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.lime),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Clinical reason is required for audit trail' : null,
                    style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Patient demonstrated improved extension control; advancing target ROM by 5%.',
                      hintStyle: const TextStyle(color: Color(0xFF55605A), fontSize: 12),
                      filled: true,
                      fillColor: AdminTheme.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AdminTheme.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AdminTheme.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _savePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.lime,
                          foregroundColor: AdminTheme.limeDark,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Save Version $nextVersion',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            filled: true,
            fillColor: AdminTheme.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AdminTheme.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
