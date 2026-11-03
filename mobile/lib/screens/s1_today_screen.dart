import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import 's10_taskproof_screen.dart';
import '../widgets/preflight_dialog.dart';

class TodayScreen extends StatelessWidget {
  final DeviceService deviceService;
  final StorageService storageService;
  final VoidCallback onStartExercise;
  final VoidCallback onNavigateDevice;

  const TodayScreen({
    super.key,
    required this.deviceService,
    required this.storageService,
    required this.onStartExercise,
    required this.onNavigateDevice,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = deviceService.state == DeviceConnectionState.streaming;
    final plan = storageService.activePlan;
    final sessions = storageService.sessions;
    final lastSession = sessions.isNotEmpty ? sessions.first : null;
    final pendingCount = storageService.pendingSyncCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(H10Tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Device Status Card
          Card(
            color: const Color(H10Tokens.colorCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(H10Tokens.colorSuccess).withOpacity(0.12)
                          : const Color(H10Tokens.colorError).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConnected ? Icons.sensors : Icons.sensors_off,
                      color: isConnected ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorError),
                    ),
                  ),
                  const SizedBox(width: H10Tokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isConnected ? 'Device Connected' : 'No Device Connected',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (deviceService.isSimulated) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SIMULATED',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1967D2)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected
                              ? 'Battery: ${deviceService.batteryPct}% • ${deviceService.currentPacketRateHz}Hz stream'
                              : 'Connect to ESP32 glove or start Simulator',
                          style: const TextStyle(fontSize: 12, color: Color(H10Tokens.colorSecondaryText)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onNavigateDevice,
                    child: Text(isConnected ? 'Manage' : 'Connect'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 2. RehabBridge NEXUS TaskProof Event Card
          Card(
            color: const Color(0xFFF0FDF4), // Emerald 50
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(0xFFBBF7D0), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(H10Tokens.colorPrimary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'INNOVATION 2K26 EVENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.fact_check_outlined, size: 20, color: Color(H10Tokens.colorPrimary)),
                        tooltip: 'Preflight Diagnostics',
                        onPressed: () => PreflightDialog.show(context),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Object Transfer Verification (TaskProof)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14532D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Live verification with ArUco marker camera tracking + 3-flex & FSR contact glove kinematics.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskProofScreen(
                                  deviceService: deviceService,
                                  storageService: storageService,
                                  initialJudgeView: false,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text('Operator View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(H10Tokens.colorPrimary),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskProofScreen(
                                  deviceService: deviceService,
                                  storageService: storageService,
                                  initialJudgeView: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.gavel, size: 16),
                          label: const Text('Judge View'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(H10Tokens.colorPrimary),
                            side: const BorderSide(color: Color(H10Tokens.colorPrimary)),
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 3. Pending Sync Badge (if any)
          if (pendingCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: H10Tokens.space16),
              padding: const EdgeInsets.symmetric(horizontal: H10Tokens.space12, vertical: H10Tokens.space8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync, size: 18, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$pendingCount session(s) pending sync to clinician dashboard.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),

          // 4. Today's Plan Card
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
                      const Flexible(
                        child: Text(
                          "TODAY'S REHABILITATION PLAN",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(H10Tokens.colorSecondaryText)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target: ${plan.targetReps} reps',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(H10Tokens.colorPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: H10Tokens.space12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(H10Tokens.colorSurfaceTint),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fitness_center, color: Color(H10Tokens.colorPrimary)),
                    ),
                    title: const Text('Fist Clench & Release', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Target ROM: ${plan.targetRomMin.toStringAsFixed(0)}–${plan.targetRomMax.toStringAsFixed(0)}% • Hold: ${plan.holdS}s'),
                  ),
                  const SizedBox(height: H10Tokens.space12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(H10Tokens.colorPrimary),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: onStartExercise,
                      child: const Text('Start Prescribed Exercise', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 5. Weekly Adherence Card
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
                  const Text(
                    'WEEKLY ADHERENCE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(H10Tokens.colorSecondaryText)),
                  ),
                  const SizedBox(height: H10Tokens.space8),
                  Row(
                    children: [
                      Text(
                        '${sessions.length} / ${plan.sessionsPerWeek}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'sessions completed this week',
                          style: TextStyle(color: Color(H10Tokens.colorSecondaryText)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (sessions.length / plan.sessionsPerWeek).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE0E5E2),
                    color: const Color(H10Tokens.colorPrimary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 6. Last Session Summary Card
          if (lastSession != null)
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
                    const Text(
                      'LAST SESSION RESULTS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(H10Tokens.colorSecondaryText)),
                    ),
                    const SizedBox(height: H10Tokens.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricColumn('Mean ROM', '${lastSession.meanRom.toStringAsFixed(1)}%'),
                        _metricColumn('Consistency', lastSession.consistency != null ? lastSession.consistency!.toStringAsFixed(0) : 'Unavailable'),
                        _metricColumn('Quality', lastSession.dataQuality.toUpperCase()),
                        _metricColumn('Pain / Fatigue', '${lastSession.painAfter} / ${lastSession.fatigueAfter}'),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(H10Tokens.space16),
              alignment: Alignment.center,
              child: const Text('No completed sessions yet. Start your first session above!'),
            ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(H10Tokens.colorSecondaryText))),
      ],
    );
  }
}
