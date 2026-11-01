import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';

class SessionSummaryScreen extends StatefulWidget {
  final String sessionId;
  final ExerciseCode exercise;
  final double durationS;
  final List<Repetition> completedReps;
  final double meanRom;
  final double maxRom;
  final ConsistencyResult consistency;
  final FatigueResult fatigue;
  final StorageService storageService;
  final DeviceService deviceService;
  final DateTime startedAt;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
    required this.exercise,
    required this.durationS,
    required this.completedReps,
    required this.meanRom,
    required this.maxRom,
    required this.consistency,
    required this.fatigue,
    required this.storageService,
    required this.deviceService,
    required this.startedAt,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  int _painRating = 2; // 0-10
  int _fatigueRating = 3; // 0-10
  final TextEditingController _noteController = TextEditingController();
  bool _isSaved = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    final dev = widget.deviceService;
    final plan = widget.storageService.activePlan;

    final session = SessionRecord(
      id: widget.sessionId,
      patientId: widget.storageService.patientId,
      exerciseCode: widget.exercise.name,
      planVersion: plan.version,
      startedAt: widget.startedAt,
      endedAt: DateTime.now(),
      durationS: widget.durationS,
      repsCompleted: widget.completedReps.length,
      repsTarget: plan.targetReps,
      meanRom: widget.meanRom,
      maxRom: widget.maxRom,
      meanRepDurationS: widget.completedReps.isNotEmpty
          ? widget.completedReps.map((r) => r.durationS).reduce((a, b) => a + b) / widget.completedReps.length
          : 0.0,
      holdS: plan.holdS,
      consistency: widget.consistency.isAvailable ? widget.consistency.totalScore : null,
      consistencyComponents: widget.consistency.toJson(),
      fatigueDropPct: widget.fatigue.isAvailable ? widget.fatigue.dropPct : null,
      painAfter: _painRating,
      fatigueAfter: _fatigueRating,
      note: _noteController.text.trim(),
      dataQuality: dev.currentDataQuality,
      dataSource: dev.isSimulated ? 'simulated' : 'real',
      deviceId: 'H10-APP-CLIENT',
      firmware: '1.0.0',
      calibrationRef: dev.activeCalibration?.id ?? 'uncalibrated',
      clientVersion: '1.0.0',
      createdAt: DateTime.now(),
      repetitions: widget.completedReps,
    );

    await widget.storageService.saveSession(session);
    setState(() => _isSaved = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved to local storage!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.storageService.activePlan;
    final completionPct = plan.targetReps > 0
        ? ((widget.completedReps.length / plan.targetReps) * 100.0).clamp(0.0, 100.0)
        : 100.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        backgroundColor: const Color(H10Tokens.colorBackground),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(H10Tokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: const Color(H10Tokens.colorCard),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                side: const BorderSide(color: Color(H10Tokens.colorBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(H10Tokens.space16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.exercise.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(H10Tokens.colorSurfaceTint),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${completionPct.toStringAsFixed(0)}% COMPLETED',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricTile('Reps Done', '${widget.completedReps.length} / ${plan.targetReps}'),
                        _metricTile('Duration', '${widget.durationS.toStringAsFixed(0)}s'),
                        _metricTile('Mean ROM', '${widget.meanRom.toStringAsFixed(1)}%'),
                        _metricTile('Max ROM', '${widget.maxRom.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: H10Tokens.space16),

            // Consistency & Fatigue Card
            Card(
              color: const Color(H10Tokens.colorCard),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                side: const BorderSide(color: Color(H10Tokens.colorBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(H10Tokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ANALYSIS & MOVEMENT QUALITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Consistency Score:'),
                        Text(
                          widget.consistency.isAvailable
                              ? '${widget.consistency.totalScore!.toStringAsFixed(1)} / 100'
                              : 'Unavailable (${widget.consistency.missingReason})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (widget.consistency.isAvailable) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ROM Ratio: ${((widget.consistency.romRatio ?? 1.0) * 100).toStringAsFixed(0)}% • Timing: ${((widget.consistency.timingScore ?? 1.0) * 100).toStringAsFixed(0)}% • Smoothness: ${((widget.consistency.smoothScore ?? 1.0) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 11, color: Color(H10Tokens.colorSecondaryText)),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Consistency score is experimental and requires physiotherapist review.',
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(H10Tokens.colorSecondaryText)),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fatigue Indicator:'),
                        Text(
                          widget.fatigue.isAvailable
                              ? (widget.fatigue.isFatigueDetected ? 'Fatigue Detected (${widget.fatigue.dropPct!.toStringAsFixed(1)}% drop)' : 'Stable Endurance')
                              : 'Unavailable (< 6 reps)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.fatigue.isFatigueDetected ? const Color(H10Tokens.colorError) : const Color(H10Tokens.colorSuccess),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: H10Tokens.space16),

            // Mandatory Pain & Fatigue Ratings
            Card(
              color: const Color(H10Tokens.colorCard),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                side: const BorderSide(color: Color(H10Tokens.colorBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(H10Tokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PATIENT REPORTED RATINGS (0–10)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                    const SizedBox(height: 12),
                    Text('Pain Rating: $_painRating / 10', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _painRating.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: const Color(H10Tokens.colorPrimary),
                      label: '$_painRating',
                      onChanged: (val) => setState(() => _painRating = val.toInt()),
                    ),
                    const SizedBox(height: 8),
                    Text('Fatigue Rating: $_fatigueRating / 10', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _fatigueRating.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: const Color(H10Tokens.colorPrimary),
                      label: '$_fatigueRating',
                      onChanged: (val) => setState(() => _fatigueRating = val.toInt()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Optional Patient Note',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: H10Tokens.space24),

            // Save Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(H10Tokens.colorPrimary),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSaved ? null : _saveSession,
                child: Text(_isSaved ? 'Saved Locally' : 'Save Session Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(H10Tokens.colorSecondaryText))),
      ],
    );
  }
}
