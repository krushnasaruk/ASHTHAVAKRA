import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class DashboardTopBar extends StatelessWidget {
  final String clinicianName;
  final VoidCallback onPrescribe;
  final ValueChanged<String>? onSearch;

  const DashboardTopBar({
    super.key,
    this.clinicianName = 'Dr. Sarah Chen',
    required this.onPrescribe,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AdminTheme.canvasBg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Greeting Title (Matching "Welcome back Taylor 👋" in reference image)
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Welcome back $clinicianName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Clinical Monitoring & Kinematics Cockpit',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 2. Search Field, Prescribe Action, Notification Bell & Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input pill (Comfortably sized with full placeholder visibility)
              Container(
                width: 230,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AdminTheme.cardBorder, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: AdminTheme.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: onSearch,
                        style: const TextStyle(fontSize: 12, color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search patients, protocols...',
                          hintStyle: TextStyle(fontSize: 11.5, color: AdminTheme.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Prescribe Action Button (Vibrant neon lime pill)
              InkWell(
                onTap: onPrescribe,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AdminTheme.lime,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AdminTheme.lime.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: Color(0xFF14181B)),
                      SizedBox(width: 6),
                      Text(
                        'Prescribe',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF14181B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Notification Bell (Clean white circle button)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 19, color: AdminTheme.textSecondary),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: CircleAvatar(
                        radius: 3.5,
                        backgroundColor: AdminTheme.sidebarBadge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Profile Avatar with Status Ring (Matching right circle in reference)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AdminTheme.pastelLavender,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SC',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AdminTheme.pastelLavenderIcon,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
