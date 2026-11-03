import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final DeviceService deviceService;
  final StorageService storageService;

  const SettingsScreen({
    super.key,
    required this.deviceService,
    required this.storageService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = true;
  bool _tremorBandEnabled = false;
  bool _colorBlindSafe = true;

  @override
  Widget build(BuildContext context) {
    final plan = widget.storageService.activePlan;
    final dev = widget.deviceService;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F0E),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0B0F0E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Therapist Prescribed Plan (Hero Obsidian Card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8F05F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRESCRIBED PLAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0B0F0E),
                        ),
                      ),
                    ),
                    Text(
                      'v${plan.version}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC8F05F)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _darkRow('Target Repetitions', '${plan.targetReps} reps'),
                _darkRow('Target ROM Band', '${plan.targetRomMin.toStringAsFixed(0)}–${plan.targetRomMax.toStringAsFixed(0)}%'),
                _darkRow('Hold Duration', '${plan.holdS}s'),
                _darkRow('Weekly Cadence', '${plan.sessionsPerWeek} sessions'),
                _darkRow('Fatigue Drop', '${plan.fatigueDropThreshold.toStringAsFixed(0)}%'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Preferences (Obsidian Dark Card)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  title: const Text('Daily Rehabilitation Reminders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                  value: _remindersEnabled,
                  activeColor: const Color(0xFFC8F05F),
                  activeTrackColor: const Color(0xFF1E2822),
                  onChanged: (v) => setState(() => _remindersEnabled = v),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18, color: Color(0xFF1E2822)),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  title: const Text('Okabe-Ito Color-Blind Palette', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                  value: _colorBlindSafe,
                  activeColor: const Color(0xFFC8F05F),
                  activeTrackColor: const Color(0xFF1E2822),
                  onChanged: (v) => setState(() => _colorBlindSafe = v),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18, color: Color(0xFF1E2822)),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  title: const Text('Tremor Band Filtering', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                  value: _tremorBandEnabled,
                  activeColor: const Color(0xFFC8F05F),
                  activeTrackColor: const Color(0xFF1E2822),
                  onChanged: (v) => setState(() => _tremorBandEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Diagnostics & Data
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2822),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.file_copy_outlined, color: Color(0xFFC8F05F), size: 18),
                  ),
                  title: const Text('Copy Diagnostics Bundle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                  onTap: () {
                    final bundle = {
                      'app_version': '2.0.0',
                      'protocol_version': 1,
                      'mode': dev.mode.name,
                      'host': dev.host,
                      'total_packets': dev.decoder.diagnostics.totalPacketsDecoded,
                      'errors': dev.decoder.diagnostics.decodeErrors,
                      'gaps': dev.decoder.diagnostics.gapsDetected,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    Clipboard.setData(ClipboardData(text: bundle.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnostics copied!')));
                  },
                ),
                const Divider(height: 1, indent: 18, endIndent: 18, color: Color(0xFF1E2822)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B1212),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 18),
                  ),
                  title: const Text('Clear Local App Storage', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF141A17),
                        title: const Text('Delete Local Storage?', style: TextStyle(color: Colors.white)),
                        content: const Text('This will delete all stored sessions on this device.', style: TextStyle(color: Color(0xFF8E958E))),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      widget.storageService.clearAllData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local storage cleared.')));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _darkRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFFA0AAB0))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
