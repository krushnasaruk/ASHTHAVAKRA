import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenPrescription;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onOpenPrescription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AdminTheme.sidebarBg,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logo & Brand Mark (Matching image header)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF25293A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AdminTheme.lime, width: 3),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AdminTheme.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Text(
                            'ASHTAVAKRA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AdminTheme.lime,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'v3',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF14181B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Text(
                            'Hand Rehab',
                            style: TextStyle(
                              fontSize: 10,
                              color: AdminTheme.sidebarTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25293A),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              '3-CH',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.lime,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 2. Navigation Menu List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  label: 'Today',
                  isSelected: selectedIndex == 0,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.view_in_ar_rounded,
                  label: 'Live HUD',
                  isSelected: selectedIndex == 1,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.verified_user_rounded,
                  label: 'TaskProof',
                  isSelected: selectedIndex == 2,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.description_rounded,
                  label: 'Audit & PDF',
                  isSelected: selectedIndex == 3,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Text(
                    'COHORT & CLINIC',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AdminTheme.sidebarTextMuted.withOpacity(0.6),
                    ),
                  ),
                ),
                _buildStaticNavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Cohort Roster',
                  onTap: () => onSelectTab(0),
                ),
                _buildStaticNavItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Clinical Alerts',
                  badgeCount: 2,
                  onTap: () => onSelectTab(0),
                ),
                _buildStaticNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Protocols',
                  onTap: onOpenPrescription,
                ),
                _buildStaticNavItem(
                  icon: Icons.tune_rounded,
                  label: 'Preflight & BLE',
                  onTap: () => onSelectTab(2),
                ),
                _buildStaticNavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 3. Bottom Card (Download our mobile app / Connect Glove - matching image)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminTheme.lime,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sensor wave graphic
                    Row(
                      children: [
                        _buildWaveBar(14),
                        const SizedBox(width: 3),
                        _buildWaveBar(22),
                        const SizedBox(width: 3),
                        _buildWaveBar(10),
                        const SizedBox(width: 3),
                        _buildWaveBar(18),
                      ],
                    ),
                    // Circular dark button with arrow
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF14181B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_outward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Download our\nmobile app',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: Color(0xFF14181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'H10 ESP32-S3 BLE Online',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14181B).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => onSelectTab(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AdminTheme.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF14181B) : AdminTheme.sidebarTextMuted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF14181B) : AdminTheme.sidebarTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticNavItem({
    required IconData icon,
    required String label,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AdminTheme.sidebarTextMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.sidebarTextMuted,
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: const BoxDecoration(
                    color: AdminTheme.sidebarBadge,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF14181B),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
