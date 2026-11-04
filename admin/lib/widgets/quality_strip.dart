import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class QualityStripWidget extends StatelessWidget {
  final bool isConnected;
  final bool isSimulated;
  final double packetRateHz;
  final int lastPacketAgeMs;
  final String dataQuality;

  const QualityStripWidget({
    super.key,
    required this.isConnected,
    this.isSimulated = false,
    this.packetRateHz = 0.0,
    this.lastPacketAgeMs = 0,
    this.dataQuality = 'good',
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor = AdminTheme.border;
    Color qualityColor = AdminTheme.lime;
    String statusText = 'Disconnected';

    if (isConnected) {
      if (lastPacketAgeMs > 500) {
        dotColor = AdminTheme.amber;
        statusText = 'Degraded';
      } else {
        dotColor = AdminTheme.lime;
        statusText = isSimulated ? 'Simulated' : 'Connected';
      }
    } else {
      dotColor = AdminTheme.crimson;
      statusText = 'Disconnected';
    }

    final q = dataQuality.toLowerCase();
    if (q == 'poor' || q == 'bad') {
      qualityColor = AdminTheme.crimson;
    } else if (q == 'fair' || q == 'degraded') {
      qualityColor = AdminTheme.amber;
    } else {
      qualityColor = AdminTheme.lime;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121715),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B26), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: dotColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isConnected ? '${packetRateHz.toStringAsFixed(0)}Hz' : '0Hz',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AdminTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: qualityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dataQuality.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: qualityColor,
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
