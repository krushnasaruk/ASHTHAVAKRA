import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/storage_service.dart';

class ProgressScreen extends StatefulWidget {
  final StorageService storageService;

  const ProgressScreen({super.key, required this.storageService});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _rangeDays = 14; // 14, 42, 365
  bool _includeSimulated = true;

  @override
  Widget build(BuildContext context) {
    final allSessions = widget.storageService.sessions;
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));

    final filteredSessions = allSessions.where((s) {
      if (s.startedAt.isBefore(cutoff)) return false;
      if (!_includeSimulated && s.dataSource == 'simulated') return false;
      return true;
    }).toList();

    final baseline = PatientBaseline.compute(
      patientId: widget.storageService.patientId,
      exerciseCode: 'fist_clench',
      allSessions: allSessions,
    );

    final flags = widget.storageService.flags;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(H10Tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range and Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: _rangeDays,
                items: const [
                  DropdownMenuItem(value: 14, child: Text('Last 2 Weeks')),
                  DropdownMenuItem(value: 42, child: Text('Last 6 Weeks')),
                  DropdownMenuItem(value: 365, child: Text('All Time')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _rangeDays = v);
                },
              ),
              Row(
                children: [
                  const Text('Include Simulated', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _includeSimulated,
                    onChanged: (v) => setState(() => _includeSimulated = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: H10Tokens.space12),

          // 1. ROM Over Time Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RANGE OF MOTION (ROM) TREND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                      if (baseline != null)
                        Text(
                          'Baseline: ${baseline.meanRom.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filteredSessions.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No sessions recorded in this time range.')))
                  else
                    Column(
                      children: filteredSessions.take(5).map((s) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.exerciseCode.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('${s.startedAt.month}/${s.startedAt.day}', style: const TextStyle(fontSize: 12, color: Color(H10Tokens.colorSecondaryText))),
                              Text('Mean: ${s.meanRom.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Max: ${s.maxRom.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
                              if (s.dataSource == 'simulated')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(3)),
                                  child: const Text('SIM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1967D2))),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${filteredSessions.length} session(s) in window. Source: ${_includeSimulated ? "Real & Simulated" : "Real only"}',
                    style: const TextStyle(fontSize: 10, color: Color(H10Tokens.colorSecondaryText)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 2. Active Clinical Flags Card
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
                  const Text('ASSISTIVE CLINICAL FLAGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                  const SizedBox(height: 12),
                  if (flags.isEmpty)
                    const Text('No clinical flags currently raised. All metrics within prescribed parameters.')
                  else
                    Column(
                      children: flags.map((f) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: f.severity == 'review' ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                f.severity == 'review' ? Icons.flag : Icons.info,
                                color: f.severity == 'review' ? const Color(H10Tokens.colorWarning) : const Color(H10Tokens.colorInfo),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(f.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(f.message, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 3. Pain & Fatigue Trend
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
                  const Text('PAIN & FATIGUE RATINGS (RECENT SESSIONS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                  const SizedBox(height: 12),
                  if (filteredSessions.isEmpty)
                    const Text('No data recorded.')
                  else
                    Column(
                      children: filteredSessions.take(5).map((s) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${s.startedAt.month}/${s.startedAt.day} ${s.startedAt.hour}:${s.startedAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12)),
                              Text('Pain: ${s.painAfter}/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Fatigue: ${s.fatigueAfter}/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

