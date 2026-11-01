import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final StorageService storageService;

  const HistoryScreen({super.key, required this.storageService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedExercise = 'all';

  @override
  Widget build(BuildContext context) {
    final allSessions = widget.storageService.sessions;
    final sessions = allSessions.where((s) {
      if (_selectedExercise != 'all' && s.exerciseCode != _selectedExercise) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: const Color(H10Tokens.colorBackground),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () {
              final csv = widget.storageService.exportCsv();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Exported CSV Preview'),
                  content: SingleChildScrollView(child: Text(csv, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _chip('all', 'All Exercises'),
                const SizedBox(width: 8),
                _chip('fist_clench', 'Fist Clench'),
                const SizedBox(width: 8),
                _chip('finger_tap', 'Finger Tap'),
                const SizedBox(width: 8),
                _chip('pinch', 'Pinch'),
                const SizedBox(width: 8),
                _chip('wrist_rotation', 'Wrist Rotation'),
                const SizedBox(width: 8),
                _chip('hand_control_game', 'Mini-Game'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Session List
          Expanded(
            child: sessions.isEmpty
                ? const Center(child: Text('No matching session records found.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(H10Tokens.space16),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: H10Tokens.space8),
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      return Card(
                        color: const Color(H10Tokens.colorCard),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                          side: const BorderSide(color: Color(H10Tokens.colorBorder)),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(s.exerciseCode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              if (s.dataSource == 'simulated')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(3)),
                                  child: const Text('SIMULATED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1967D2))),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${s.startedAt.month}/${s.startedAt.day} • ${s.repsCompleted} reps • Mean ROM: ${s.meanRom.toStringAsFixed(1)}% • Quality: ${s.dataQuality.toUpperCase()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                s.syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_upload,
                                size: 18,
                                color: s.syncStatus == 'synced' ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorWarning),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Color(H10Tokens.colorError)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete Session?'),
                                      content: const Text('This will delete the session record locally.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(H10Tokens.colorError), foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    widget.storageService.deleteSession(s.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String key, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _selectedExercise == key,
      onSelected: (val) {
        if (val) setState(() => _selectedExercise = key);
      },
    );
  }
}
