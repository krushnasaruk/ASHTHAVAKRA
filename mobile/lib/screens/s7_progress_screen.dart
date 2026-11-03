import 'dart:math' as math;
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
  int _rangeDays = 14; // 1, 14 ('Last 2 Weeks'), 42 ('Last 6 Weeks'), 365 ('All Time')
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Paytin Header & Time Range Pills (Includes exact 'Last 2 Weeks' for tests)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF161C19),
                ),
              ),
              Row(
                children: [
                  const Text('Simulated', style: TextStyle(fontSize: 11, color: Color(0xFF7A837E))),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _includeSimulated,
                      activeColor: const Color(0xFF121715),
                      activeTrackColor: const Color(0xFFC8F05F),
                      onChanged: (v) => setState(() => _includeSimulated = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Segmented Pills (Paytin Style)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimePill('Today', 1),
                const SizedBox(width: 8),
                _buildTimePill('Last 2 Weeks', 14),
                const SizedBox(width: 8),
                _buildTimePill('Last 6 Weeks', 42),
                const SizedBox(width: 8),
                _buildTimePill('All Time', 365),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                    borderRadius: BorderRadius.circular(22),
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
                      const Text(
                        '+24%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121715),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Prescribed ROM increased vs baseline across 3 active channels.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF223028),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Goal Dots (Paytin 10-dot sequence)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Goal: 8/10 Reps',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF121715),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '80%',
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
                          final isFilled = i < 8;
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121715),
                    borderRadius: BorderRadius.circular(22),
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
                      const SizedBox(height: 4),
                      const Text(
                        'Finger Flex Distribution',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFFA0AAB0),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Radar / Spider Chart
                      SizedBox(
                        height: 95,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _KinematicsRadarPainter(),
                        ),
                      ),
                      const SizedBox(height: 6),

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
          const SizedBox(height: 18),

          // 3. Paytin Overview & Stacked Adherence Bar Chart
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E7DE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                    const Flexible(
                      child: Text(
                        'Overview & Adherence',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF161C19),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune, size: 12, color: Color(0xFF121715)),
                          SizedBox(width: 4),
                          Text('Filters', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main Metric Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Session Adherence',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF7A837E)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '94% Completed',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF161C19),
                          ),
                        ),
                      ],
                    ),
                    if (baseline != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Baseline Mean ROM',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF7A837E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${baseline.meanRom.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF121715),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Paytin Dual-Tone Stacked Bar Chart (Mon - Sun with Tooltip)
                SizedBox(
                  height: 130,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStackedBar('Mon', 0.5, 0.3),
                      _buildStackedBar('Tue', 0.7, 0.4),
                      _buildStackedBar('Wed', 0.4, 0.2),
                      _buildStackedBar('Thu', 0.8, 0.5),
                      _buildStackedBar('Fri', 1.0, 0.8, hasTooltip: true, tooltip: '10 Reps • Fri'),
                      _buildStackedBar('Sat', 0.6, 0.4),
                      _buildStackedBar('Sun', 0.9, 0.7),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Session History List (ROM over time)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Session Logs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF161C19),
                ),
              ),
              Text(
                '${filteredSessions.length} sessions',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A837E)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (filteredSessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text(
                'No sessions recorded in this time range.',
                style: TextStyle(color: Color(0xFF7A837E)),
              ),
            )
          else
            ...filteredSessions.take(5).map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E7DE)),
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
                      child: const Icon(Icons.show_chart, color: Color(0xFFC8F05F), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.exerciseCode.toUpperCase(),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${s.startedAt.month}/${s.startedAt.day} • ${s.startedAt.hour.toString().padLeft(2, '0')}:${s.startedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF7A837E)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Mean: ${s.meanRom.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF121715)),
                        ),
                        Text(
                          'Max: ${s.maxRom.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF7A837E)),
                        ),
                      ],
                    ),
                    if (s.dataSource == 'simulated') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SIM',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1967D2)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimePill(String title, int days) {
    final isSelected = _rangeDays == days;
    return InkWell(
      onTap: () => setState(() => _rangeDays = days),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC8F05F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFC8F05F) : const Color(0xFFE2E7DE),
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
            color: const Color(0xFF121715),
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

  Widget _buildStackedBar(String day, double totalHeightFraction, double limeFraction, {bool hasTooltip = false, String tooltip = ''}) {
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
            color: hasTooltip ? const Color(0xFF121715) : const Color(0xFF7A837E),
          ),
        ),
      ],
    );
  }
}

/// Custom Painter for Kinematics Radar / Spider Chart in Obsidian Card
class _KinematicsRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    final gridPaint = Paint()
      ..color = const Color(0xFF232D28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Concentric web polygons
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

    // Kinematic Values: Thumb 0.82, Index 0.78, Middle 0.74, Ring 0.4, Pinky 0.35
    final values = [0.82, 0.78, 0.74, 0.4, 0.35];
    final shapePath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final r = radius * values[i];
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
