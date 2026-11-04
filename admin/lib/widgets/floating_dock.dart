import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import 'vector_icons.dart';

class FloatingBottomDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onCenterTap;

  const FloatingBottomDock({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF101614),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF222B26), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDockItem(
              index: 0,
              icon: Icons.calendar_today_rounded,
              label: 'Today',
              isSelected: selectedIndex == 0,
            ),
          ),
          Expanded(
            child: _buildDockItem(
              index: 1,
              icon: Icons.fitness_center_rounded,
              label: 'Live HUD',
              isSelected: selectedIndex == 1,
            ),
          ),

          // Center Glowing Action Button (Screenshot 1)
          GestureDetector(
            onTap: onCenterTap,
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AdminTheme.lime,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AdminTheme.lime.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sensors_rounded,
                  color: Color(0xFF0B0F0E),
                  size: 22,
                ),
              ),
            ),
          ),

          Expanded(
            child: _buildDockItem(
              index: 2,
              customIcon: VectorIcon.taskProof(size: 19, color: selectedIndex == 2 ? AdminTheme.lime : const Color(0xFF6B7771)),
              label: 'TaskProof',
              isSelected: selectedIndex == 2,
            ),
          ),
          Expanded(
            child: _buildDockItem(
              index: 3,
              icon: Icons.assignment_outlined,
              label: 'Audit & PDF',
              isSelected: selectedIndex == 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    IconData? icon,
    Widget? customIcon,
    required String label,
    required bool isSelected,
  }) {
    const activeColor = AdminTheme.lime;
    const inactiveColor = Color(0xFF6B7771);

    return InkWell(
      onTap: () => onSelectTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ??
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : inactiveColor,
                ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
