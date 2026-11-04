import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../theme/admin_theme.dart';

class FingerBarsWidget extends StatelessWidget {
  final List<double> normalizedFlex; // [thumb, index, middle, ring, pinky] (0-100)
  final double? fsrContact;          // Palmar FSR contact percentage (0-100)
  final double targetRomMin;
  final double targetRomMax;
  final bool isConnected;

  const FingerBarsWidget({
    super.key,
    required this.normalizedFlex,
    this.fsrContact,
    this.targetRomMin = 70.0,
    this.targetRomMax = 100.0,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    // Measured channels: Thumb, Index, Middle
    // Estimated channels: Ring (0.90 * middle), Pinky (0.75 * middle)
    final middleVal = normalizedFlex.length > 2 ? normalizedFlex[2] : 0.0;
    final effectiveFlex = List<double>.generate(5, (i) {
      if (!isConnected) return 0.0;
      if (i < 3) {
        return i < normalizedFlex.length ? normalizedFlex[i] : 0.0;
      } else if (i == 3) {
        return (middleVal * 0.90).clamp(0.0, 100.0);
      } else {
        return (middleVal * 0.75).clamp(0.0, 100.0);
      }
    });

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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'FINGER FLEXION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isConnected ? AdminTheme.pastelMint : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isConnected ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: isConnected ? AdminTheme.pastelMintIcon : AdminTheme.crimson,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Text(
                  'Target: ${targetRomMin.toStringAsFixed(0)}–${targetRomMax.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5 Finger Vertical Flexion Bars
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final val = effectiveFlex[index];
                final color = Color(H10Tokens.fingerColors[index]);
                final isEstimated = index >= 3;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Text(
                        isConnected ? '${val.toStringAsFixed(0)}%' : 'NO DATA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isConnected ? AdminTheme.textPrimary : AdminTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 38,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isConnected && val >= targetRomMin ? color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 38,
                          height: isConnected ? (val / 100.0) * 110.0 : 0.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D26),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            H10Tokens.fingerNames[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          if (isEstimated) ...[
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'EST.',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AdminTheme.cardBorder, height: 1),
          const SizedBox(height: 14),

          // Palmar FSR Contact
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PALMAR FSR CONTACT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  isConnected && fsrContact != null
                      ? '${fsrContact!.toStringAsFixed(1)}% (${((fsrContact! / 100.0) * 15.0).toStringAsFixed(1)} N)'
                      : 'NO DATA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isConnected && fsrContact != null ? AdminTheme.green : AdminTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (isConnected && fsrContact != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (fsrContact! / 100.0).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFEDEFF5),
                color: AdminTheme.green,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
