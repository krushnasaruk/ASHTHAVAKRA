import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import 's10_taskproof_screen.dart';
import 's8_history_screen.dart';
import '../widgets/preflight_dialog.dart';
import '../widgets/hand_view.dart';
import '../widgets/anatomy_hand_view.dart';
import '../widgets/vector_icons.dart';
import '../theme/app_theme.dart';
import '../dev/mock_data.dart';

class TodayScreen extends StatefulWidget {
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
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _showAnatomyView = false;

  @override
  Widget build(BuildContext context) {
    final deviceService = widget.deviceService;
    final storageService = widget.storageService;
    final onStartExercise = widget.onStartExercise;
    final onNavigateDevice = widget.onNavigateDevice;

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
                  'Care Team & Prescriber',
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
              children: kUseMockData
                  ? DevMockData.mockCareTeam
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildCareAvatar(context, m.initials, m.name, m.color),
                          ))
                      .toList()
                  : [
                      _buildCareAvatar(context, 'DR', plan.setBy.split(' ').first, const Color(0xFFC8F05F)),
                      const SizedBox(width: 16),
                      _buildCareAvatar(context, 'AI', 'Kinematics', const Color(0xFF56B4E9)),
                      const SizedBox(width: 16),
                      _buildCareAvatar(context, 'PT', 'Lead Physio', const Color(0xFF009E73)),
                    ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. 3D Interactive Hand & Anatomical Skeleton Views
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: c.isDark ? const Color(0xFF141816) : const Color(0xFFE8ECE9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.cardBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _build3DViewTab('3D HAND', !_showAnatomyView, () => setState(() => _showAnatomyView = false)),
                    const SizedBox(width: 3),
                    _build3DViewTab('3D ANATOMY', _showAnatomyView, () => setState(() => _showAnatomyView = true)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => Scaffold(
                        backgroundColor: const Color(0xFF000000),
                        appBar: AppBar(
                          backgroundColor: const Color(0xFF000000),
                          elevation: 0,
                          iconTheme: const IconThemeData(color: Color(0xFFE8EFEF)),
                          title: const Text(
                            'HAND / ANATOMY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Color(0xFFE8EFEF),
                            ),
                          ),
                        ),
                        body: AnatomyHandView(
                          normalizedFlex: widget.deviceService.latestNormalizedFlex,
                          imu: widget.deviceService.latestPacket?.imu,
                          isConnected: isStreaming,
                          isFullScreen: true,
                          onClose: () => Navigator.pop(ctx),
                        ),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: c.isDark ? const Color(0xFF141816) : const Color(0xFFE8ECE9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.cardBorder, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, color: c.textSecondary, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        'FULLSCREEN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Render selected 3D View (Realistic Hand or 27-Bone Anatomical Skeleton)
          _showAnatomyView
              ? AnatomyHandView(
                  normalizedFlex: widget.deviceService.latestNormalizedFlex,
                  imu: widget.deviceService.latestPacket?.imu,
                  isConnected: isStreaming,
                )
              : HandView(
                  normalizedFlex: widget.deviceService.latestNormalizedFlex,
                  imu: widget.deviceService.latestPacket?.imu,
                  isConnected: isStreaming,
                  height: 250,
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
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(storageService: storageService),
                    ),
                  );
                },
                child: Text(
                  'See all >',
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

          Builder(
            builder: (context) {
              final activeSessions = sessions.isNotEmpty
                  ? sessions
                  : (kUseMockData ? DevMockData.createMockSessions() : <SessionRecord>[]);

              if (activeSessions.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.cardBorder, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history, color: c.textSecondary, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'No exercise sessions recorded yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start an exercise session above to begin your rehabilitation program.',
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: activeSessions.take(3).map((s) {
                  final isClench = s.exerciseCode.contains('clench');
                  final isPinch = s.exerciseCode.contains('pinch');
                  final icon = isClench
                      ? VectorIcon.routines(size: 18, color: c.iconTint)
                      : (isPinch
                          ? VectorIcon.pinch(size: 18, color: c.iconTint)
                          : VectorIcon.taskProof(size: 18, color: c.iconTint));

                  final durationMin = (s.durationS / 60).toStringAsFixed(1);
                  final badgeText = '${s.repsCompleted} Reps • ${s.meanRom.toStringAsFixed(0)}% ROM';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildActivityCard(
                      context,
                      title: s.exerciseCode.replaceAll('_', ' ').toUpperCase(),
                      subtitle: '${durationMin}m duration • ${s.dataQuality.toUpperCase()}',
                      badge: badgeText,
                      badgeColor: c.isDark ? const Color(0xFF1E2822) : const Color(0xFFC8F05F),
                      badgeTextColor: c.isDark ? const Color(0xFFC8F05F) : const Color(0xFF121715),
                      iconWidget: icon,
                    ),
                  );
                }).toList(),
              );
            },
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

  Widget _build3DViewTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8F05F) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: isSelected ? const Color(0xFF121715) : const Color(0xFF8E958E),
          ),
        ),
      ),
    );
  }
}
