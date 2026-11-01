import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';

class FingerBarsWidget extends StatelessWidget {
  final List<double> normalizedFlex; // 5 values: thumb to pinky (0-100)
  final double targetRomMin;
  final double targetRomMax;

  const FingerBarsWidget({
    super.key,
    required this.normalizedFlex,
    this.targetRomMin = 70.0,
    this.targetRomMax = 100.0,
  });

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'FINGER FLEXION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(H10Tokens.colorSecondaryText),
                ),
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
              final val = index < normalizedFlex.length ? normalizedFlex[index] : 0.0;
              final color = Color(H10Tokens.fingerColors[index]);
              final name = H10Tokens.fingerNames[index];
              final inTarget = val >= targetRomMin && val <= targetRomMax;

              return Column(
                children: [
                  Text(
                    '${val.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: inTarget ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorText),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 110,
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
                          bottom: (targetRomMin / 100.0) * 110,
                          child: Container(
                            width: 32,
                            height: ((targetRomMax - targetRomMin) / 100.0) * 110,
                            color: const Color(0x33A7B9A3),
                          ),
                        ),
                        // Fill bar
                        FractionallySizedBox(
                          heightFactor: (val / 100.0).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
