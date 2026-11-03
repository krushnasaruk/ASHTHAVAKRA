import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';

/// Clean, real-time Finger Flexion & Palmar Contact panel.
/// Strictly displays live values from device telemetry or "NO DATA" / "CONNECT DEVICE"
/// when disconnected. No simulated or default numbers are presented in production.
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
        // Ring = 0.9 * middle
        return (middleVal * 0.90).clamp(0.0, 100.0);
      } else {
        // Pinky = 0.75 * middle
        return (middleVal * 0.75).clamp(0.0, 100.0);
      }
    });

    return Container(
      padding: const EdgeInsets.all(H10Tokens.space12),
      decoration: BoxDecoration(
        color: const Color(H10Tokens.colorCard),
        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
        border: Border.all(color: const Color(H10Tokens.colorBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'FINGER FLEXION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Color(H10Tokens.colorSecondaryText),
                    ),
                  ),
                  if (!isConnected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF332014),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF5A623), width: 0.8),
                      ),
                      child: const Text(
                        'CONNECT DEVICE',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF5A623),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Target: ${targetRomMin.toStringAsFixed(0)}–${targetRomMax.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(H10Tokens.colorSecondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: H10Tokens.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final val = effectiveFlex[index];
              final color = Color(H10Tokens.fingerColors[index]);
              final name = H10Tokens.fingerNames[index];
              final inTarget = isConnected && val >= targetRomMin && val <= targetRomMax;
              final isEstimated = index >= 3;

              return Column(
                children: [
                  Text(
                    isConnected ? '${val.toStringAsFixed(0)}%' : 'NO DATA',
                    style: TextStyle(
                      fontSize: isConnected ? 12 : 9.5,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: !isConnected
                          ? const Color(0xFF8E958E)
                          : (inTarget ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorText)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(H10Tokens.colorBorder)),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Target band highlight
                        Positioned(
                          bottom: (targetRomMin / 100.0) * 100,
                          child: Container(
                            width: 32,
                            height: ((targetRomMax - targetRomMin) / 100.0) * 100,
                            color: const Color(0x33A7B9A3),
                          ),
                        ),
                        // Fill bar
                        FractionallySizedBox(
                          heightFactor: isConnected ? (val / 100.0).clamp(0.0, 1.0) : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isConnected ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      if (isEstimated) ...[
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B261A),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFF5A623), width: 0.6),
                          ),
                          child: const Text(
                            'EST.',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF5A623),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            }),
          ),
          if (fsrContact != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PALMAR FSR CONTACT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorSecondaryText)),
                ),
                Text(
                  isConnected ? '${fsrContact!.toStringAsFixed(0)}%' : 'NO DATA',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? const Color(0xFFC8F05F) : const Color(0xFF8E958E),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
