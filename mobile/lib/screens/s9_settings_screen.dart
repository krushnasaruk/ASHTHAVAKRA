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
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
        backgroundColor: const Color(H10Tokens.colorBackground),
      ),
      body: ListView(
        padding: const EdgeInsets.all(H10Tokens.space16),
        children: [
          // 1. Therapist Prescribed Plan (Read-Only)
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
                  const Text('PRESCRIBED PLAN PARAMETERS (READ-ONLY)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                  const SizedBox(height: 8),
                  Text('Set by: ${plan.setBy} (Plan v${plan.version})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _row('Target Repetitions', '${plan.targetReps} reps'),
                  _row('Target ROM Band', '${plan.targetRomMin.toStringAsFixed(0)}–${plan.targetRomMax.toStringAsFixed(0)}%'),
                  _row('Hold Duration', '${plan.holdS} seconds'),
                  _row('Prescribed Cadence', '${plan.sessionsPerWeek} sessions / week'),
                  _row('Fatigue Drop Threshold', '${plan.fatigueDropThreshold.toStringAsFixed(0)}%'),
                  const SizedBox(height: 4),
                  const Text('Note: Parameters can only be modified by your physiotherapist in the clinician dashboard.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(H10Tokens.colorSecondaryText))),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 2. Reminders & Accessibility
          Card(
            color: const Color(H10Tokens.colorCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily Rehabilitation Reminders'),
                  subtitle: const Text('Local reminder at 10:00 AM & 5:00 PM'),
                  value: _remindersEnabled,
                  activeColor: const Color(H10Tokens.colorPrimary),
                  onChanged: (v) => setState(() => _remindersEnabled = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Okabe-Ito Color-Blind Palette'),
                  subtitle: const Text('High-contrast distinguishable finger indicators'),
                  value: _colorBlindSafe,
                  activeColor: const Color(H10Tokens.colorPrimary),
                  onChanged: (v) => setState(() => _colorBlindSafe = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Experimental Tremor Band (Phase 2)'),
                  subtitle: const Text('3–12 Hz bandpass oscillation energy (research only)'),
                  value: _tremorBandEnabled,
                  activeColor: const Color(H10Tokens.colorPrimary),
                  onChanged: (v) => setState(() => _tremorBandEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 3. Diagnostics & Exports
          Card(
            color: const Color(H10Tokens.colorCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_copy, color: Color(H10Tokens.colorPrimary)),
                  title: const Text('Copy Diagnostics Bundle'),
                  subtitle: const Text('Version, protocol, and decoder counters (no PII)'),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Color(H10Tokens.colorError)),
                  title: const Text('Clear Local App Storage', style: TextStyle(color: Color(H10Tokens.colorError))),
                  subtitle: const Text('Deletes all local session recordings and calibration'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Local Storage?'),
                        content: const Text('This will delete all stored sessions on this device.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(H10Tokens.colorError), foregroundColor: Colors.white),
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
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(H10Tokens.colorSecondaryText))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
