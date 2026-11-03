import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  final StorageService storageService;

  const ProgressScreen({super.key, required this.storageService});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _rangeDays = 14; // 1, 14 ('Last 2 Weeks'), 42 ('Last 6 Weeks'), 365 ('All Time')
  bool _includeSimulated = true;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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

    // Dynamic recovery metrics computed from real session records
    final double romGain;
    if (filteredSessions.isNotEmpty && baseline != null && baseline.meanRom > 0) {
      final currentMean = filteredSessions.map((s) => s.meanRom).reduce((a, b) => a + b) / filteredSessions.length;
      romGain = ((currentMean - baseline.meanRom) / baseline.meanRom) * 100.0;
    } else {
      romGain = 0.0;
    }
    final romGainStr = romGain >= 0 ? '+${romGain.toStringAsFixed(0)}%' : '${romGain.toStringAsFixed(0)}%';

    final plan = widget.storageService.activePlan;
    final totalCompletedReps = filteredSessions.fold<int>(0, (sum, s) => sum + s.repsCompleted);
    final weeklyTargetReps = plan.targetReps * plan.sessionsPerWeek;
    final repGoalFraction = weeklyTargetReps > 0 ? (totalCompletedReps / weeklyTargetReps).clamp(0.0, 1.0) : 0.0;
    final filledDots = (repGoalFraction * 10).round();

    final weeklySessionsTarget = plan.sessionsPerWeek;
    final adherenceFraction = weeklySessionsTarget > 0 ? (filteredSessions.length / weeklySessionsTarget).clamp(0.0, 1.0) : 0.0;
    final adherencePct = (adherenceFraction * 100).toInt();

    // Daily distribution Mon..Sun
    final dayReps = List<int>.filled(7, 0);
    for (final s in filteredSessions) {
      final wIdx = s.startedAt.weekday - 1;
      if (wIdx >= 0 && wIdx < 7) {
        dayReps[wIdx] += s.repsCompleted;
      }
    }
    final maxDayRep = math.max(1, dayReps.reduce(math.max));

    // Radar Kinematics polygon computed from real session ROM
    final List<double> radarValues;
    if (filteredSessions.isNotEmpty) {
      final meanRomFrac = (filteredSessions.map((s) => s.meanRom).reduce((a, b) => a + b) / filteredSessions.length / 100.0).clamp(0.15, 1.0);
      radarValues = [meanRomFrac, (meanRomFrac * 0.95).clamp(0.15, 1.0), (meanRomFrac * 0.90).clamp(0.15, 1.0), 0.35, 0.30];
    } else {
      radarValues = [0.20, 0.20, 0.20, 0.20, 0.20];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Paytin Header & Time Range Pills (Includes exact 'Last 2 Weeks' for tests)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text('Simulated', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _includeSimulated,
                      activeColor: const Color(0xFFC8F05F),
                      activeTrackColor: c.isDark ? const Color(0xFF1E2822) : const Color(0xFFE2E7DE),
                      onChanged: (v) => setState(() => _includeSimulated = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Segmented Pills (Paytin Style)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimePill(context, 'Today', 1),
                const SizedBox(width: 8),
                _buildTimePill(context, 'Last 2 Weeks', 14),
                const SizedBox(width: 8),
                _buildTimePill(context, 'Last 6 Weeks', 42),
                const SizedBox(width: 8),
                _buildTimePill(context, 'All Time', 365),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. Paytin Dual Split Cards Row (Lime ROM Gain Card + Obsidian Kinematics Spider Card)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Card: Solid Vibrant Lime #C8F05F Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F05F),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8F05F).withOpacity(0.35),
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
                          const Row(
                            children: [
                              Icon(Icons.trending_up, size: 16, color: Color(0xFF121715)),
                              SizedBox(width: 4),
                              Text(
                                'ROM Gain',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF121715),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121715),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '3-CH',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFC8F05F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        romGainStr,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121715),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'vs baseline target',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF223028),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Goal Dots (Paytin 10-dot sequence)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Goal: $totalCompletedReps/${plan.targetReps} Reps',
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF121715),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(repGoalFraction * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF121715).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(10, (i) {
                          final isFilled = i < filledDots;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              height: 6,
                              decoration: BoxDecoration(
                                color: isFilled ? const Color(0xFF121715) : Colors.black.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Right Card: Obsidian Black #121715 Kinematics Radar Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121715),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF232D28), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                          const Text(
                            'Kinematics',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E2822),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.hub, size: 12, color: Color(0xFFC8F05F)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Radar / Spider Chart
                      SizedBox(
                        height: 95,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _KinematicsRadarPainter(values: radarValues),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Channel Legend Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendDot('Ch1', const Color(0xFFE69F00)),
                          _buildLegendDot('Ch2', const Color(0xFF56B4E9)),
                          _buildLegendDot('Ch3', const Color(0xFF009E73)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Paytin Overview & Stacked Adherence Bar Chart
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: c.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(c.isDark ? 0.18 : 0.04),
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
                    Flexible(
                      child: Text(
                        'Overview & Adherence',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.iconContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune, size: 12, color: c.iconTint),
                          const SizedBox(width: 4),
                          Text('Filters', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Metric Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Adherence',
                          style: TextStyle(fontSize: 11, color: c.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$adherencePct% Completed',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (baseline != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Baseline Mean ROM',
                            style: TextStyle(fontSize: 11, color: c.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${baseline.meanRom.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC8F05F),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                // Paytin Dual-Tone Stacked Bar Chart (Mon - Sun with Tooltip)
                SizedBox(
                  height: 130,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStackedBar(context, 'Mon', (dayReps[0] / maxDayRep).clamp(0.08, 1.0), (dayReps[0] / maxDayRep * 0.6).clamp(0.04, 0.8), hasTooltip: dayReps[0] > 0, tooltip: '${dayReps[0]} Reps • Mon'),
                      _buildStackedBar(context, 'Tue', (dayReps[1] / maxDayRep).clamp(0.08, 1.0), (dayReps[1] / maxDayRep * 0.6).clamp(0.04, 0.8), hasTooltip: dayReps[1] > 0, tooltip: '${dayReps[1]} Reps • Tue'),
                      _buildStackedBar(context, 'Wed', (dayReps[2] / maxDayRep).clamp(0.08, 1.0), (dayReps[2] / maxDayRep * 0.6).clamp(0.04, 0.8), hasTooltip: dayReps[2] > 0, tooltip: '${dayReps[2]} Reps • Wed'),
                      _buildStackedBar(context, 'Thu', (dayReps[3] / maxDayRep).clamp(0.08, 1.0), (dayReps[3] / maxDayRep * 0.6).clamp(0.04, 0.8), hasTooltip: dayReps[3] > 0, tooltip: '${dayReps[3]} Reps • Thu'),
                      _buildStackedBar(context, 'Fri', (dayReps[4] / maxDayRep).clamp(0.08, 1.0), (dayReps[4] / maxDayRep * 0.6).clamp(0.04, 0.8), hasTooltip: dayReps[4] > 0, tooltip: '${dayReps[4]} Reps • Fri'),
                      _buildStackedBar(context, 'Sat', (dayReps[5] / maxDayRep).clamp(0.08, 1.0), (dayReps[5] / maxDayRep * 0.6).clamp(0.04, 0.8), hasTooltip: dayReps[5] > 0, tooltip: '${dayReps[5]} Reps • Sat'),
                      _buildStackedBar(context, 'Sun', (dayReps[6] / maxDayRep).clamp(0.08, 1.0), (dayReps[6] / maxDayRep * 0.6).clamp(0.04, 0.8), hasTooltip: dayReps[6] > 0, tooltip: '${dayReps[6]} Reps • Sun'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Session History List (ROM over time)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Sessions',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                '${filteredSessions.length} sessions',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (filteredSessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text(
                'No sessions recorded in this time range.',
                style: TextStyle(color: c.textSecondary),
              ),
            )
          else
            ...filteredSessions.take(4).map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.cardBorder),
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
                      child: Icon(Icons.show_chart, color: c.iconTint, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.exerciseCode.toUpperCase(),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.textPrimary),
                          ),
                          Text(
                            '${s.startedAt.month}/${s.startedAt.day} • ${s.startedAt.hour.toString().padLeft(2, '0')}:${s.startedAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 11, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${s.meanRom.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.isDark ? const Color(0xFFC8F05F) : const Color(0xFF121715)),
                        ),
                        Text(
                          'Max ${s.maxRom.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTimePill(BuildContext context, String title, int days) {
    final c = AppColors.of(context);
    final isSelected = _rangeDays == days;
    return InkWell(
      onTap: () => setState(() => _rangeDays = days),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8F05F) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFC8F05F) : c.cardBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC8F05F).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0B0F0E) : c.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFFA0AAB0))),
      ],
    );
  }

  Widget _buildStackedBar(BuildContext context, String day, double totalHeightFraction, double limeFraction, {bool hasTooltip = false, String tooltip = ''}) {
    final c = AppColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasTooltip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF121715),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tooltip,
              style: const TextStyle(fontSize: 8.5, color: Color(0xFFC8F05F), fontWeight: FontWeight.bold),
            ),
          )
        else
          const SizedBox(height: 18),
        Container(
          width: 22,
          height: 70 * totalHeightFraction,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFF121715),
          ),
          child: Column(
            children: [
              Container(
                height: (70 * totalHeightFraction) * (1 - limeFraction),
                decoration: const BoxDecoration(
                  color: Color(0xFFC8F05F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: hasTooltip ? FontWeight.bold : FontWeight.w500,
            color: hasTooltip ? c.textPrimary : c.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _KinematicsRadarPainter extends CustomPainter {
  final List<double> values;

  _KinematicsRadarPainter({this.values = const [0.2, 0.2, 0.2, 0.2, 0.2]});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    final gridPaint = Paint()
      ..color = const Color(0xFF232D28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int ring = 1; ring <= 3; ring++) {
      final r = radius * (ring / 3.0);
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi / 5) - math.pi / 2;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final shapePath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final val = i < values.length ? values[i] : 0.2;
      final r = radius * val;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        shapePath.moveTo(x, y);
      } else {
        shapePath.lineTo(x, y);
      }
    }
    shapePath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFFC8F05F).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shapePath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFC8F05F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(shapePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _KinematicsRadarPainter oldDelegate) =>
      oldDelegate.values != values;
}
