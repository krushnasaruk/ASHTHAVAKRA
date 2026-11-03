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
  bool _tremorBandEnabled = false; // Phase 2 off by default
  bool _colorBlindSafe = true;

  @override
  Widget build(BuildContext context) {
    final plan = widget.storageService.activePlan;
    final dev = widget.deviceService;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        title: const Text(
          'Settings & Configuration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFFF4F6F0),
        foregroundColor: const Color(0xFF161C19),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Therapist Prescribed Plan (Obsidian Hero Card)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121715),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF232D28), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'PRESCRIBED PLAN (READ-ONLY)',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121715),
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_outline, size: 16, color: Color(0xFFC8F05F)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Set by: ${plan.setBy} (Plan v${plan.version})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                ),
                const SizedBox(height: 12),
                _darkRow('Target Repetitions', '${plan.targetReps} reps'),
                _darkRow('Target ROM Band', '${plan.targetRomMin.toStringAsFixed(0)}–${plan.targetRomMax.toStringAsFixed(0)}%'),
                _darkRow('Hold Duration', '${plan.holdS} seconds'),
                _darkRow('Prescribed Cadence', '${plan.sessionsPerWeek} sessions / week'),
                _darkRow('Fatigue Drop Threshold', '${plan.fatigueDropThreshold.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                const Text(
                  'Note: Parameters can only be modified by your physiotherapist in the clinician dashboard.',
                  style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFFA0AAB0)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Reminders & Accessibility (White Card with Neon Lime Switches)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E7DE), width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily Rehabilitation Reminders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Local reminder at 10:00 AM & 5:00 PM', style: TextStyle(fontSize: 11, color: Color(0xFF7A837E))),
                  value: _remindersEnabled,
                  activeColor: const Color(0xFF121715),
                  activeTrackColor: const Color(0xFFC8F05F),
                  onChanged: (v) => setState(() => _remindersEnabled = v),
                ),
                const Divider(height: 1, color: Color(0xFFF0F4EC)),
                SwitchListTile(
                  title: const Text('Okabe-Ito Color-Blind Palette', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('High-contrast distinguishable finger indicators', style: TextStyle(fontSize: 11, color: Color(0xFF7A837E))),
                  value: _colorBlindSafe,
                  activeColor: const Color(0xFF121715),
                  activeTrackColor: const Color(0xFFC8F05F),
                  onChanged: (v) => setState(() => _colorBlindSafe = v),
                ),
                const Divider(height: 1, color: Color(0xFFF0F4EC)),
                SwitchListTile(
                  title: const Text('Experimental Tremor Band (Phase 2)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('3–12 Hz bandpass oscillation energy (research only)', style: TextStyle(fontSize: 11, color: Color(0xFF7A837E))),
                  value: _tremorBandEnabled,
                  activeColor: const Color(0xFF121715),
                  activeTrackColor: const Color(0xFFC8F05F),
                  onChanged: (v) => setState(() => _tremorBandEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Diagnostics & Exports
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E7DE), width: 1.2),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121715),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.file_copy, color: Color(0xFFC8F05F), size: 18),
                  ),
                  title: const Text('Copy Diagnostics Bundle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Version, protocol, and decoder counters (no PII)', style: TextStyle(fontSize: 11, color: Color(0xFF7A837E))),
                  onTap: () {
                    final bundle = {
                      'app_version': '1.0.0',
                      'protocol_version': 1,
                      'mode': dev.mode.name,
                      'host': dev.host,
                      'total_packets': dev.decoder.diagnostics.totalPacketsDecoded,
                      'errors': dev.decoder.diagnostics.decodeErrors,
                      'gaps': dev.decoder.diagnostics.gapsDetected,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    Clipboard.setData(ClipboardData(text: bundle.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnostics bundle copied to clipboard!')));
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF0F4EC)),
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_forever, color: Color(0xFFDC2626), size: 18),
                  ),
                  title: const Text('Clear Local App Storage', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: const Text('Deletes all local session recordings and calibration', style: TextStyle(fontSize: 11, color: Color(0xFF7A837E))),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text('Delete Local Storage?'),
                        content: const Text('This will delete all stored sessions on this device.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _darkRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFFA0AAB0))),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
