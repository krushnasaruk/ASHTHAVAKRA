import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../theme/admin_theme.dart';

class ClinicalFlagBadge extends StatelessWidget {
  final ClinicalFlag flag;
  final VoidCallback? onTap;

  const ClinicalFlagBadge({
    super.key,
    required this.flag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeBg;
    String severityLabel;

    switch (flag.severity.toLowerCase()) {
      case 'urgent':
      case 'critical':
        badgeColor = AdminTheme.red;
        badgeBg = AdminTheme.red.withOpacity(0.12);
        severityLabel = 'CRITICAL';
        break;
      case 'warning':
      case 'warn':
        badgeColor = AdminTheme.amber;
        badgeBg = AdminTheme.amber.withOpacity(0.12);
        severityLabel = 'WARNING';
        break;
      case 'review':
      default:
        badgeColor = AdminTheme.cyan;
        badgeBg = AdminTheme.cyan.withOpacity(0.12);
        severityLabel = 'REVIEW';
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.border, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withOpacity(0.4)),
              ),
              child: Text(
                severityLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Patient ${flag.patientId}',
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        flag.type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    flag.message,
                    style: const TextStyle(
                      color: Color(0xFFC0CAC4),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
