import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';

class OverviewScreen extends StatelessWidget {
  final ApiService apiService;
  final ValueChanged<String> onSelectPatient;
  final VoidCallback onOpenLiveMonitor;
  final VoidCallback onOpenTaskProof;

  const OverviewScreen({
    super.key,
    required this.apiService,
    required this.onSelectPatient,
    required this.onOpenLiveMonitor,
    required this.onOpenTaskProof,
  });

  @override
  Widget build(BuildContext context) {
    final patients = apiService.patients;
    final flags = apiService.flags;
    final defaultPlan = apiService.getPatientActivePlan('P-014');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SECTION 1: "New Courses" (Top 3 Stat Cards + Hero Promo Card)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Regimens & Telemetry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: AdminTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: onOpenLiveMonitor,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final top3Cards = [
                _buildCourseCard(
                  pastelColor: AdminTheme.pastelPeach,
                  iconColor: AdminTheme.pastelPeachIcon,
                  icon: Icons.fitness_center_rounded,
                  title: 'Active Protocol',
                  subtitle: '${(defaultPlan?.exerciseId ?? "Fist Clench").replaceAll("_", " ")} • 10 Reps',
                  rating: '4.9',
                  type: 'ROM Target 70%+',
                  onTap: onOpenLiveMonitor,
                ),
                _buildCourseCard(
                  pastelColor: AdminTheme.pastelMint,
                  iconColor: AdminTheme.pastelMintIcon,
                  icon: Icons.sensors_rounded,
                  title: 'TELEMETRY STREAM',
                  subtitle: '921,600 BAUD',
                  subtitleWidget: const Row(
                    children: [
                      Text(
                        '921,600',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'BAUD',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.pastelMintIcon,
                        ),
                      ),
                    ],
                  ),
                  rating: '5.0',
                  type: 'ESP32-S3 N16R8 • 16-BIT ADS1115',
                  onTap: onOpenLiveMonitor,
                ),
                _buildCourseCard(
                  pastelColor: AdminTheme.pastelLavender,
                  iconColor: AdminTheme.pastelLavenderIcon,
                  icon: Icons.verified_user_rounded,
                  title: 'TaskProof™ Guard',
                  subtitle: '7-State Pipeline',
                  rating: '4.8',
                  type: 'Vision + FSR Locked',
                  onTap: onOpenTaskProof,
                ),
              ];

              final heroPromoCard = _buildHeroPromoCard(context);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: [
                          Expanded(child: top3Cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: top3Cards[1]),
                          const SizedBox(width: 14),
                          Expanded(child: top3Cards[2]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: heroPromoCard,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: top3Cards[0]),
                      const SizedBox(width: 12),
                      Expanded(child: top3Cards[1]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: top3Cards[2]),
                      const SizedBox(width: 12),
                      Expanded(child: heroPromoCard),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Quick Action Pills Ribbon
          Row(
            children: [
              _buildQuickPill('TaskProof™', AdminTheme.pastelLavender, AdminTheme.pastelLavenderIcon, onOpenTaskProof),
              const SizedBox(width: 8),
              _buildQuickPill('Judge View', AdminTheme.pastelMint, AdminTheme.pastelMintIcon, onOpenTaskProof),
              const SizedBox(width: 8),
              _buildQuickPill('Live Stream', AdminTheme.pastelPeach, AdminTheme.pastelPeachIcon, onOpenLiveMonitor),
              const SizedBox(width: 8),
              _buildQuickPill('Preflight', AdminTheme.pastelYellow, AdminTheme.pastelYellowIcon, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preflight Check: BLE Online, ADS1115 Calibrated (16-bit), IMU Locked.'),
                    backgroundColor: Color(0xFF141A17),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // 2. SECTION 2: Hours Activity Bar Chart + Daily Schedule + Mini Calendar
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;

              final hoursCard = _buildHoursActivityCard();
              final scheduleCard = _buildDailyScheduleCard();
              final calendarCard = _buildCalendarCard();

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: hoursCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: scheduleCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: calendarCard),
                  ],
                );
              }

              return Column(
                children: [
                  hoursCard,
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: scheduleCard),
                      const SizedBox(width: 14),
                      Expanded(child: calendarCard),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. SECTION 3: Course You're Taking (Cohort Roster) + Assignments (Clinical Flags)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;

              final cohortCard = _buildCohortRosterCard(patients);
              final assignmentsCard = _buildClinicalFlagsCard(flags);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: cohortCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: assignmentsCard),
                  ],
                );
              }

              return Column(
                children: [
                  cohortCard,
                  const SizedBox(height: 14),
                  assignmentsCard,
                ],
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS (Matching the Reference Image Exactly) ---

  Widget _buildCourseCard({
    required Color pastelColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? subtitleWidget,
    required String rating,
    required String type,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastel squircle icon
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: pastelColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      subtitleWidget ??
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AdminTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AdminTheme.cardBorder, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5A623)),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPromoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.heroCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminTheme.lime, width: 2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ASHTAVAKRA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'TaskProof™ Engine',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Deterministic physical verification with ArUco vision lock & FSR grip detection.',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA0A7B8),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onOpenLiveMonitor,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AdminTheme.lime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Launch Real-Time Live HUD',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14181B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPill(String label, Color pastelBg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursActivityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
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
                'Hours Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AdminTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Weekly', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 13, color: AdminTheme.textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.arrow_outward_rounded, size: 12, color: AdminTheme.green),
              SizedBox(width: 4),
              Text(
                '+3% increase than last week',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar Chart with Floating Tooltip (matching reference image)
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildChartBar('Su', 35, false),
                    _buildChartBar('Mo', 65, false),
                    _buildChartBar('Tu', 50, false),
                    _buildChartBar('We', 20, false),
                    _buildChartBar('Th', 105, true), // Active Peak Day
                    _buildChartBar('Fr', 25, false),
                    _buildChartBar('Sa', 60, false),
                  ],
                ),
              ),

              // Tooltip above Thursday bar
              Positioned(
                top: 2,
                left: 175,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14181B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '6h 45 min',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '4 Nov 2026',
                        style: TextStyle(fontSize: 7.5, color: Color(0xFFA0A7B8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double height, bool isPeak) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: isPeak ? AdminTheme.lime : const Color(0xFF1A1D26),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AdminTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Schedule',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildScheduleItem(
            color: AdminTheme.pastelPeach,
            iconColor: AdminTheme.pastelPeachIcon,
            icon: Icons.grid_view_rounded,
            title: 'Design System',
            subtitle: 'Lecture - Class • Patient P-014',
          ),
          const SizedBox(height: 10),
          _buildScheduleItem(
            color: AdminTheme.pastelLavender,
            iconColor: AdminTheme.pastelLavenderIcon,
            icon: Icons.pin_drop_rounded,
            title: 'Typography',
            subtitle: 'Group - Test • Patient P-002',
          ),
          const SizedBox(height: 10),
          _buildScheduleItem(
            color: AdminTheme.pastelMint,
            iconColor: AdminTheme.pastelMintIcon,
            icon: Icons.palette_rounded,
            title: 'Color Style',
            subtitle: 'Group - Test • Patient P-005',
          ),
          const SizedBox(height: 10),
          _buildScheduleItem(
            color: AdminTheme.pastelYellow,
            iconColor: AdminTheme.pastelYellowIcon,
            icon: Icons.layers_rounded,
            title: 'Visual Design',
            subtitle: 'Lecture - Test • Patient P-009',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: AdminTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: AdminTheme.textTertiary),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.chevron_left, size: 18, color: AdminTheme.textSecondary),
              Text(
                'August, 2023',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.textPrimary,
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AdminTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 12),

          // Days of Week
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('S', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
              Text('M', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
              Text('T', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
              Text('W', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
              Text('T', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
              Text('F', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
              Text('S', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Grid Numbers (matching reference with 17 highlighted in lime circle)
          Column(
            children: [
              _buildCalendarRow(['29', '30', '1', '2', '3', '4', '5'], false),
              const SizedBox(height: 6),
              _buildCalendarRow(['6', '7', '8', '9', '10', '11', '12'], false),
              const SizedBox(height: 6),
              _buildCalendarRow(['13', '14', '15', '16', '17', '18', '19'], true), // 17 highlighted
              const SizedBox(height: 6),
              _buildCalendarRow(['20', '21', '22', '23', '24', '25', '26'], false),
              const SizedBox(height: 6),
              _buildCalendarRow(['27', '28', '29', '30', '31', '1', '2'], false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarRow(List<String> days, bool containsActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) {
        final isActive = (d == '17');
        if (isActive) {
          return Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AdminTheme.lime,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                d,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14181B),
                ),
              ),
            ),
          );
        }
        final isFaint = (int.tryParse(d) ?? 0) > 28 && days.indexOf(d) < 3;
        return SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Text(
              d,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isFaint ? AdminTheme.textTertiary.withOpacity(0.4) : AdminTheme.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCohortRosterCard(List<dynamic> patients) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
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
                  Text(
                    'Course You\'re Taking',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ENROLLED COHORT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Active', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 13, color: AdminTheme.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AdminTheme.lime,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Icon(Icons.add, size: 14, color: Color(0xFF14181B))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Patient Roster Rows matching image with circular progress rings
          _buildCohortRow(
            color: AdminTheme.pastelLavender,
            iconColor: AdminTheme.pastelLavenderIcon,
            icon: Icons.view_in_ar_rounded,
            title: 'Patient P-014',
            subtitle: '3D Design Course • Right Hand Paresis',
            time: '8h 45 min',
            progressPct: 45,
            onTap: () => onSelectPatient('P-014'),
          ),
          const SizedBox(height: 12),
          _buildCohortRow(
            color: AdminTheme.pastelPeach,
            iconColor: AdminTheme.pastelPeachIcon,
            icon: Icons.code_rounded,
            title: 'Patient P-002',
            subtitle: 'Development Basics • MCP Arthroplasty',
            time: '16h 12 min',
            progressPct: 75,
            onTap: () => onSelectPatient('P-002'),
          ),
          const SizedBox(height: 12),
          _buildCohortRow(
            color: AdminTheme.pastelMint,
            iconColor: AdminTheme.pastelMintIcon,
            icon: Icons.query_stats_rounded,
            title: 'Patient P-005',
            subtitle: 'Data Analytics • Radial Neuropathy',
            time: 'Completed',
            progressPct: 100,
            onTap: () => onSelectPatient('P-005'),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortRow({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required int progressPct,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Remaining', style: TextStyle(fontSize: 8.5, color: AdminTheme.textTertiary)),
                Text(time, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
              ],
            ),
          ),
          // Circular Progress Arc
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progressPct / 100.0,
                  backgroundColor: const Color(0xFFEDEFF5),
                  color: AdminTheme.green,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$progressPct%',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AdminTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalFlagsCard(List<dynamic> flags) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
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
                  Text(
                    'Assignments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '• CLINICAL FLAGS',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AdminTheme.lime,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Icon(Icons.add, size: 14, color: Color(0xFF14181B))),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildAssignmentRow(
            color: AdminTheme.pastelLavender,
            iconColor: AdminTheme.pastelLavenderIcon,
            icon: Icons.hub_rounded,
            title: 'Methods of data • Spasm Guard',
            time: '02 July, 10:30 AM',
            status: 'In progress',
            statusBg: AdminTheme.pastelLavender,
            statusColor: AdminTheme.pastelLavenderIcon,
          ),
          const SizedBox(height: 12),
          _buildAssignmentRow(
            color: AdminTheme.pastelMint,
            iconColor: AdminTheme.pastelMintIcon,
            icon: Icons.wifi_protected_setup_rounded,
            title: 'Market Research • Tremor 3.2Hz',
            time: '14 June, 12:45 AM',
            status: 'Completed',
            statusBg: AdminTheme.pastelMint,
            statusColor: AdminTheme.pastelMintIcon,
          ),
          const SizedBox(height: 12),
          _buildAssignmentRow(
            color: AdminTheme.pastelPeach,
            iconColor: AdminTheme.pastelPeachIcon,
            icon: Icons.data_usage_rounded,
            title: 'Data Collection • Wrist Flexion',
            time: '12 May, 11:00 AM',
            status: 'Upcoming',
            statusBg: AdminTheme.pastelPeach,
            statusColor: AdminTheme.pastelPeachIcon,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentRow({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String time,
    required String status,
    required Color statusBg,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
