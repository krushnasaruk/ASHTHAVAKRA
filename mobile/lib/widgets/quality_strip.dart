import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../dev/mock_data.dart';
import '../theme/app_theme.dart';

class QualityStripWidget extends StatelessWidget {
  final bool isConnected;
  final bool isSimulated;
  final int packetRateHz;
  final int lastPacketAgeMs;
  final String dataQuality; // 'good', 'reduced', 'invalid'

  const QualityStripWidget({
    super.key,
    required this.isConnected,
    required this.isSimulated,
    required this.packetRateHz,
    required this.lastPacketAgeMs,
    this.dataQuality = 'good',
  });

  Color _qualityColor() {
    if (!isConnected) return const Color(H10Tokens.colorError);
    switch (dataQuality) {
      case 'good':
        return const Color(H10Tokens.colorSuccess);
      case 'reduced':
        return const Color(H10Tokens.colorWarning);
      default:
        return const Color(H10Tokens.colorError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: H10Tokens.space12, vertical: H10Tokens.space8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Connection & Simulator Badge
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorError),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              if (isSimulated && kUseMockData) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF1967D2)),
                  ),
                  child: const Text(
                    'SIMULATED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF1967D2),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Stream rate & Data quality
          Row(
            children: [
              Text(
                '${packetRateHz}Hz',
                style: TextStyle(
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _qualityColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dataQuality.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _qualityColor(),
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

