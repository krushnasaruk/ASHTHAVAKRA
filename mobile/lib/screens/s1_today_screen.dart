import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import 's10_taskproof_screen.dart';
import '../widgets/preflight_dialog.dart';
import '../widgets/holographic_hand_scan.dart';

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
    final isStreaming = deviceService.state == DeviceConnectionState.streaming;
    final plan = storageService.activePlan;
    final sessions = storageService.sessions;
    final lastSession = sessions.isNotEmpty ? sessions.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Paytin Master Telemetry Card (Hero Obsidian Card)
          InkWell(
            onTap: onNavigateDevice,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF121715), // Obsidian black
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFF232D28), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Brand + Wave Chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ASHTAVAKRA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E2822),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFC8F05F),
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                      // Neon Lime Contactless / Telemetry Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8F05F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi, color: Color(0xFF121715), size: 12),
                            SizedBox(width: 3),
                            Text(
                              '3-CH',
                              style: TextStyle(
                                color: Color(0xFF121715),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Middle Value (Paytin Big Balance Style -> Telemetry Baud / Stream)
                  const Text(
                    'TELEMETRY STREAM',
                    style: TextStyle(
                      color: Color(0xFF7A837E),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        isStreaming
                            ? '${deviceService.currentPacketRateHz.toStringAsFixed(1)} Hz'
                            : '921,600',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isStreaming ? 'STREAM' : 'BAUD',
                        style: const TextStyle(
                          color: Color(0xFFC8F05F),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Hardware Specification Mask
                  const Text(
                    'ESP32-S3 N16R8 • 16-BIT ADS1115',
                    style: TextStyle(
                      color: Color(0xFFA0AAB0),
                      fontSize: 11,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Bottom Card Details: Profile & Power (Rule 8: USB 5V VBUS)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HARDWARE PROFILE',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'demo3 (3-CH Active)',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'POWER SUPPLY',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.usb, color: Color(0xFFC8F05F), size: 13),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    deviceService.batteryStatus,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Paytin 4 Squircle Quick Action Buttons
          Row(
            children: [
              _buildSquircleAction(
                context,
                icon: Icons.verified_outlined,
                label: 'TaskProof',
                onTap: () {
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
              ),
              const SizedBox(width: 8),
              _buildSquircleAction(
                context,
                icon: Icons.gavel_outlined,
                label: 'Judge View',
                onTap: () {
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
              ),
              const SizedBox(width: 8),
              _buildSquircleAction(
                context,
                icon: Icons.fitness_center_outlined,
                label: 'Routines',
                onTap: onStartExercise,
              ),
              const SizedBox(width: 8),
              _buildSquircleAction(
                context,
                icon: Icons.fact_check_outlined,
                label: 'Preflight',
                onTap: () => PreflightDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Care Team & Investigators Horizontal Avatars (Paytin "Quick Send" style)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Care Team & Investigators',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161C19),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => PreflightDialog.show(context),
                child: const Text(
                  'Team >',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A837E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCareAvatar('VJ', 'Vaishnavi', 'UI Lead', const Color(0xFF56B4E9)),
                const SizedBox(width: 12),
                _buildCareAvatar('RP', 'Rajendra', 'Hardware', const Color(0xFFE69F00)),
                const SizedBox(width: 12),
                _buildCareAvatar('GS', 'Gautam', 'Embedded', const Color(0xFF009E73)),
                const SizedBox(width: 12),
                _buildCareAvatar('KS', 'Krushna', 'Patient/Dev', const Color(0xFFC8F05F)),
                const SizedBox(width: 12),
                _buildCareAvatar('DJ', 'Dr. Joshi', 'Physio Lead', const Color(0xFFE4C41B)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. 3D Holographic Hand Scanner Card (Obsidian Container)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
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
                    const Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar, size: 15, color: Color(0xFFC8F05F)),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '3D HOLOGRAPHIC SCAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => deviceService.toggleHardwareProfile(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2822),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC8F05F).withOpacity(0.4)),
                        ),
                        child: Text(
                          deviceService.hardwareProfile == 'demo3' ? '3-CH (ACTIVE)' : '5-CH (FULL)',
                          style: const TextStyle(
                            color: Color(0xFFC8F05F),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Real-time kinematic joint curl with Okabe-Ito finger channels & palmar EVA contact buffer.',
                  style: TextStyle(color: Color(0xFFA0AAB0), fontSize: 10.5),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: HolographicHandScanWidget(
                    flexValues: deviceService.latestNormalizedFlex,
                    fsrContact: (deviceService.latestPacket?.fsr ?? 0) / 32767.0 * 100.0,
                    isDemo3: deviceService.hardwareProfile == 'demo3',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Prescribed Rehabilitation Plan Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E7DE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8F05F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRESCRIBED PLAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121715),
                        ),
                      ),
                    ),
                    Text(
                      'Target: ${plan.targetReps} reps',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF161C19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121715),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fitness_center, color: Color(0xFFC8F05F), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fist Clench & Release',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF161C19),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Target ROM: ${plan.targetRomMin.toStringAsFixed(0)}–${plan.targetRomMax.toStringAsFixed(0)}% • Hold: ${plan.holdS}s',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF7A837E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Adherence Row (Exact substring: 'sessions completed this week')
                Row(
                  children: [
                    Text(
                      '${sessions.length} / ${plan.sessionsPerWeek}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF121715),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'sessions completed this week',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF7A837E),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (sessions.length / plan.sessionsPerWeek).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE2E7DE),
                    color: const Color(0xFF121715),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 12),

                // Large Neon Lime Start Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onStartExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8F05F),
                      foregroundColor: const Color(0xFF121715),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Prescribed Exercise',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Innovation 2K26 Event Card (TaskProof Object Transfer)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121715),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'INNOVATION 2K26 EVENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC8F05F),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fact_check_outlined, size: 18, color: Color(0xFF121715)),
                      tooltip: 'Preflight Diagnostics',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => PreflightDialog.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Object Transfer Verification (TaskProof)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Live verification with ArUco marker camera tracking + 3-flex & FSR contact glove kinematics.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                ),
                const SizedBox(height: 10),
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
                        icon: const Icon(Icons.tune, size: 15),
                        label: const Text('Operator View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF121715),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          minimumSize: const Size(0, 40),
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
                        icon: const Icon(Icons.gavel, size: 15),
                        label: const Text('Judge View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF121715),
                          side: const BorderSide(color: Color(0xFF121715), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 7. Recent Activity (Paytin Style Activity List)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF161C19),
                ),
              ),
              const Text(
                'See all >',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A837E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildActivityCard(
            title: 'Fist Clench Routine',
            subtitle: lastSession != null
                ? 'Mean ROM: ${lastSession.meanRom.toStringAsFixed(1)}%'
                : '10 Reps • 70-100% ROM Band',
            badge: 'VERIFIED 4.2s',
            badgeColor: const Color(0xFFC8F05F),
            badgeTextColor: const Color(0xFF121715),
            icon: Icons.fitness_center,
          ),
          const SizedBox(height: 8),

          _buildActivityCard(
            title: 'ArUco Marker Transfer',
            subtitle: 'Object Handover Task #42',
            badge: 'JUDGE VERIFIED',
            badgeColor: const Color(0xFF121715),
            badgeTextColor: const Color(0xFFC8F05F),
            icon: Icons.qr_code,
          ),
          const SizedBox(height: 8),

          _buildActivityCard(
            title: 'Thumb-Index Pinch',
            subtitle: 'Ch1 Thumb + Ch2 Index • 12 Reps',
            badge: '+84% ROM',
            badgeColor: const Color(0xFFE2E7DE),
            badgeTextColor: const Color(0xFF161C19),
            icon: Icons.pinch,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSquircleAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7DE), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF121715), size: 16),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF161C19),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareAvatar(String initials, String name, String role, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF121715),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF161C19),
          ),
        ),
        Text(
          role,
          style: const TextStyle(
            fontSize: 8.5,
            color: Color(0xFF7A837E),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7DE), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF121715),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFC8F05F), size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161C19),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF7A837E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
