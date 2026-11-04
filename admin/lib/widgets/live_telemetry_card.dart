import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class LiveTelemetryCard extends StatelessWidget {
  final List<double> normalizedFlex; // [thumb, index, middle, ring, pinky] in 0-100%
  final double fsrContact;           // 0-100%
  final double targetRomMin;
  final double targetRomMax;
  final double packetRateHz;
  final int currentRep;
  final int targetReps;
  final String exerciseState;
  final bool isStreaming;

  const LiveTelemetryCard({
    super.key,
    required this.normalizedFlex,
    this.fsrContact = 0.0,
    this.targetRomMin = 70.0,
    this.targetRomMax = 100.0,
    this.packetRateHz = 25.0,
    this.currentRep = 0,
    this.targetReps = 10,
    this.exerciseState = 'WAITING',
    this.isStreaming = true,
  });

  @override
  Widget build(BuildContext context) {
    final fingers = [
      {'name': 'Thumb', 'color': AdminTheme.colorThumb, 'val': normalizedFlex.isNotEmpty ? normalizedFlex[0] : 0.0, 'est': false},
      {'name': 'Index', 'color': AdminTheme.colorIndex, 'val': normalizedFlex.length > 1 ? normalizedFlex[1] : 0.0, 'est': false},
      {'name': 'Middle', 'color': AdminTheme.colorMiddle, 'val': normalizedFlex.length > 2 ? normalizedFlex[2] : 0.0, 'est': false},
      {'name': 'Ring', 'color': AdminTheme.colorRing, 'val': normalizedFlex.length > 3 ? normalizedFlex[3] : 0.0, 'est': true},
      {'name': 'Pinky', 'color': AdminTheme.colorPinky, 'val': normalizedFlex.length > 4 ? normalizedFlex[4] : 0.0, 'est': true},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.40),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Stream status, rate, & exercise state
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isStreaming ? AdminTheme.lime : AdminTheme.red,
                      boxShadow: isStreaming
                          ? [BoxShadow(color: AdminTheme.lime.withOpacity(0.6), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isStreaming ? 'LIVE TELEMETRY STREAM' : 'TELEMETRY DISCONNECTED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AdminTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AdminTheme.border),
                    ),
                    child: Text(
                      '${packetRateHz.toStringAsFixed(1)} HZ',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AdminTheme.lime,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AdminTheme.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AdminTheme.amber.withOpacity(0.3)),
                    ),
                    child: Text(
                      exerciseState.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AdminTheme.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Repetition & Target Progress Strip
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REPETITION PROGRESS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentRep / $targetReps REPS',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TARGET RANGE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${targetRomMin.toStringAsFixed(0)}% – ${targetRomMax.toStringAsFixed(0)}% ROM',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AdminTheme.lime,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 5-Finger Flexion Vertical Bars
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: fingers.map((f) {
                final double val = (f['val'] as double).clamp(0.0, 100.0);
                final Color col = f['color'] as Color;
                final bool isEst = f['est'] as bool;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          isStreaming ? '${val.toStringAsFixed(0)}%' : '--',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isStreaming ? col : AdminTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161C19),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AdminTheme.borderSubtle),
                            ),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Target ROM Zone Guideline
                                Positioned(
                                  bottom: (targetRomMin / 100.0) * 80,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 1.5,
                                    color: AdminTheme.lime.withOpacity(0.4),
                                  ),
                                ),
                                // Animated Live Level
                                FractionallySizedBox(
                                  heightFactor: isStreaming ? (val / 100.0).clamp(0.02, 1.0) : 0.02,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: col,
                                      borderRadius: BorderRadius.circular(7),
                                      boxShadow: [
                                        BoxShadow(
                                          color: col.withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, -2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f['name'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.textPrimary,
                              ),
                            ),
                            if (isEst) ...[
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AdminTheme.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'EST.',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    color: AdminTheme.amber,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Palmar FSR Pressure Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AdminTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, color: AdminTheme.cyan, size: 16),
                const SizedBox(width: 10),
                const Text(
                  'PALMAR FSR CONTACT:',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AdminTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isStreaming ? (fsrContact / 100.0).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: const Color(0xFF161E1A),
                      color: AdminTheme.cyan,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isStreaming ? '${fsrContact.toStringAsFixed(1)}%' : 'NO DATA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: fsrContact > 15 ? AdminTheme.cyan : AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
