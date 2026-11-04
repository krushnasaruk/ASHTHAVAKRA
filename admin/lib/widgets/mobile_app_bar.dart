import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class MobileAppBar extends StatelessWidget {
  final String patientId;
  final bool isWidescreenMode;
  final VoidCallback onToggleWidescreen;
  final VoidCallback onActionTap;

  const MobileAppBar({
    super.key,
    required this.patientId,
    required this.isWidescreenMode,
    required this.onToggleWidescreen,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0F0E),
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Patient Avatar (Screenshot 1)
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A17),
                    shape: BoxShape.circle,
                    border: Border.all(color: AdminTheme.lime, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      patientId.replaceAll('-', '').toUpperCase(),
                      style: const TextStyle(
                        color: AdminTheme.lime,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0B0F0E), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Header titles (Screenshot 1)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ASHTAVAKRA',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AdminTheme.lime,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AdminTheme.lime.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Text(
                            'v3',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0B0F0E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Hand Rehab',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AdminTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2822),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFF2E3D34), width: 0.8),
                          ),
                          child: const Text(
                            '3-CH',
                            style: TextStyle(
                              fontSize: 8,
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

            // Action Pill (Screenshot 1: "+ Calibrate" or "+ Prescribe")
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminTheme.lime,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AdminTheme.lime.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, size: 13, color: Color(0xFF0B0F0E)),
                    SizedBox(width: 4),
                    Text(
                      'Prescribe',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B0F0E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Canvas Mode Switcher (Widescreen Cockpit vs Mobile Canvas)
            IconButton(
              icon: Icon(
                isWidescreenMode ? Icons.phone_android : Icons.desktop_windows,
                size: 20,
                color: AdminTheme.textSecondary,
              ),
              tooltip: isWidescreenMode ? 'Switch to Mobile Canvas' : 'Switch to Widescreen Cockpit',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onToggleWidescreen,
            ),
          ],
        ),
      ),
    );
  }
}
