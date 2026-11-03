import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import 's10_taskproof_screen.dart';
import '../widgets/preflight_dialog.dart';
import '../widgets/holographic_hand_scan.dart';
import '../widgets/vector_icons.dart';
import '../theme/app_theme.dart';

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
    final c = AppColors.of(context);
    final isStreaming = deviceService.state == DeviceConnectionState.streaming;
    final plan = storageService.activePlan;
    final sessions = storageService.sessions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Paytin Master Telemetry Hero Card (Obsidian Black)
          InkWell(
            onTap: onNavigateDevice,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF121715),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 24,
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
                      const Row(
                        children: [
                          Text(
                            'ASHTAVAKRA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFC8F05F),
                            size: 13,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                  const SizedBox(height: 20),

                  // Telemetry Stream Value
                  const Text(
                    'TELEMETRY STREAM',
                    style: TextStyle(
                      color: Color(0xFF7A837E),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isStreaming
                            ? '${deviceService.currentPacketRateHz.toStringAsFixed(1)} Hz'
                            : '921,600',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isStreaming ? 'STREAM' : 'BAUD',
                        style: const TextStyle(
                          color: Color(0xFFC8F05F),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  const Text(
                    'ESP32-S3 N16R8 • 16-BIT ADS1115',
                    style: TextStyle(
                      color: Color(0xFFA0AAB0),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Card Details: Profile & Power (Rule 8 compliant)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROFILE',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'demo3 (3-CH)',
                              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'POWER',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.usb, color: Color(0xFFC8F05F), size: 13),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    deviceService.batteryStatus,
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 22),

          // 2. Paytin 4 Squircle Quick Action Buttons (Guaranteed 100% Canvas Vector Icons)
          Row(
            children: [
              _buildSquircleAction(
                context,
                iconWidget: VectorIcon.taskProof(size: 20, color: c.iconTint),
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
              const SizedBox(width: 10),
              _buildSquircleAction(
                context,
                iconWidget: VectorIcon.judge(size: 20, color: c.iconTint),
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
              const SizedBox(width: 10),
              _buildSquircleAction(
                context,
                iconWidget: VectorIcon.routines(size: 20, color: c.iconTint),
                label: 'Routines',
                onTap: onStartExercise,
              ),
              const SizedBox(width: 10),
              _buildSquircleAction(
                context,
                iconWidget: VectorIcon.preflight(size: 20, color: c.iconTint),
                label: 'Preflight',
                onTap: () => PreflightDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Care Team & Investigators Horizontal Avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Care Team & Investigators',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => PreflightDialog.show(context),
                child: Text(
                  'Team >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCareAvatar(context, 'VJ', 'Vaishnavi', const Color(0xFF56B4E9)),
                const SizedBox(width: 16),
                _buildCareAvatar(context, 'RP', 'Rajendra', const Color(0xFFE69F00)),
                const SizedBox(width: 16),
                _buildCareAvatar(context, 'GS', 'Gautam', const Color(0xFF009E73)),
                const SizedBox(width: 16),
                _buildCareAvatar(context, 'KS', 'Krushna', const Color(0xFFC8F05F)),
                const SizedBox(width: 16),
                _buildCareAvatar(context, 'DJ', 'Dr. Joshi', const Color(0xFFE4C41B)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. 3D Holographic Hand Scanner (Obsidian Container - Clean & Visual)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121715),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF232D28), width: 1.2),
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
                    const Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar, size: 15, color: Color(0xFFC8F05F)),
                          SizedBox(width: 6),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2822),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC8F05F).withOpacity(0.4)),
                        ),
                        child: Text(
                          deviceService.hardwareProfile == 'demo3' ? '3-CH ACTIVE' : '5-CH FULL',
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
                const SizedBox(height: 12),
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
          const SizedBox(height: 24),

          // 5. Prescribed Plan Card (Adaptive Dual-Mode Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: c.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(c.isDark ? 0.20 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
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
                          color: Color(0xFF121715),
                        ),
                      ),
                    ),
                    Text(
                      'Target: ${plan.targetReps} reps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.iconContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: VectorIcon.routines(size: 22, color: c.iconTint),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fist Clench & Release',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Adherence progress indicator
                Row(
                  children: [
                    Text(
                      '${sessions.length} / ${plan.sessionsPerWeek}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'sessions completed this week',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (sessions.length / plan.sessionsPerWeek).clamp(0.0, 1.0),
                    backgroundColor: c.iconContainer,
                    color: const Color(0xFFC8F05F),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 18),

                // Large Glowing Neon Lime CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onStartExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8F05F),
                      foregroundColor: const Color(0xFF121715),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 6. Recent Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                'See all >',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildActivityCard(
            context,
            title: 'Fist Clench Routine',
            subtitle: 'Today, 10:30 AM',
            badge: 'VERIFIED 4.2s',
            badgeColor: const Color(0xFFC8F05F),
            badgeTextColor: const Color(0xFF121715),
            iconWidget: VectorIcon.routines(size: 18, color: c.iconTint),
          ),
          const SizedBox(height: 10),

          _buildActivityCard(
            context,
            title: 'ArUco Marker Transfer',
            subtitle: 'Object Handover Task #42',
            badge: 'JUDGE VERIFIED',
            badgeColor: c.isDark ? const Color(0xFF1E2822) : const Color(0xFF121715),
            badgeTextColor: const Color(0xFFC8F05F),
            iconWidget: VectorIcon.qrCode(size: 18, color: c.iconTint),
          ),
          const SizedBox(height: 10),

          _buildActivityCard(
            context,
            title: 'Thumb-Index Pinch',
            subtitle: 'Ch1 Thumb + Ch2 Index • 12 Reps',
            badge: '+84% ROM',
            badgeColor: c.isDark ? const Color(0xFF1E2822) : const Color(0xFFE2E7DE),
            badgeTextColor: c.isDark ? const Color(0xFFC8F05F) : const Color(0xFF161C19),
            iconWidget: VectorIcon.pinch(size: 18, color: c.iconTint),
          ),

          // Ample bottom breathing room so content scrolls completely above floating dock
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSquircleAction(
    BuildContext context, {
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(c.isDark ? 0.20 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.iconContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
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

  Widget _buildCareAvatar(BuildContext context, String initials, String name, Color color) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
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
                fontSize: 13.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required Widget iconWidget,
  }) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.cardBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.iconContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 9.5,
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
