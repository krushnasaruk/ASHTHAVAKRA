import 'package:flutter/material.dart';

/// Camera Tracking & Tabletop Zone Field Visualizer for ASHTHAVAKRA.
/// Renders OpenCV ArUco Marker #0 tracking across Zone A (Source) and Zone B (Target),
/// with real-time lift elevation indicator and 4-guard verification telemetry.
class CameraZoneTrackerWidget extends StatelessWidget {
  final bool markerDetected;
  final String currentZone;      // 'zone_a', 'zone_b', 'transit', or 'none'
  final double detectionRate;    // 0.0 - 1.0 (rolling 1s rate)
  final double frameAgeMs;       // latency
  final bool contactEngaged;     // Palmar FSR
  final bool objectLifted;       // > 30mm elevation
  final bool transportVerified;  // crossed zone boundary
  final bool releaseConfirmed;   // released in target zone

  const CameraZoneTrackerWidget({
    super.key,
    required this.markerDetected,
    required this.currentZone,
    this.detectionRate = 1.0,
    this.frameAgeMs = 38.0,
    this.contactEngaged = false,
    this.objectLifted = false,
    this.transportVerified = false,
    this.releaseConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isZoneA = currentZone.toLowerCase().contains('a');
    final isZoneB = currentZone.toLowerCase().contains('b');
    final isTransit = currentZone.toLowerCase().contains('transit') ||
        (markerDetected && !isZoneA && !isZoneB);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070D14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Camera Status & ArUco Marker Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: markerDetected
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF3366),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'OPENCV ARUCO TRACKER',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Text(
                  'MARKER ID #0 • DICT_4X4_50',
                  style: TextStyle(
                    color: markerDetected
                        ? const Color(0xFF00E676)
                        : const Color(0xFF94A3B8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tabletop Visual Arena: Zone A -> Transit -> Zone B
          Container(
            height: 95,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B131E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Stack(
              children: [
                // Zone Labels & Dividers
                Row(
                  children: [
                    // Zone A (Start)
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isZoneA
                              ? const Color(0xFF00E676).withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isZoneA
                                ? const Color(0xFF00E676)
                                : const Color(0xFF334155),
                            width: isZoneA ? 1.5 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ZONE A',
                                style: TextStyle(
                                  color: isZoneA
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'START / PICKUP',
                                style: TextStyle(
                                  color: isZoneA
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFF475569),
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Transit Centerline
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: isTransit
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),

                    // Zone B (Target)
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isZoneB
                              ? const Color(0xFF00E5FF).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isZoneB
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF334155),
                            width: isZoneB ? 1.5 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ZONE B',
                                style: TextStyle(
                                  color: isZoneB
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'TARGET RELEASE',
                                style: TextStyle(
                                  color: isZoneB
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF475569),
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Active Payload Marker (Simulated position based on currentZone)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  alignment: isZoneA
                      ? const Alignment(-0.75, 0.0)
                      : (isZoneB
                          ? const Alignment(0.75, 0.0)
                          : (isTransit ? const Alignment(0.0, 0.0) : const Alignment(-0.75, 0.0))),
                  child: markerDetected
                      ? Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.view_in_ar,
                              size: 18,
                              color: Color(0xFF070D14),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4-Guard Verification Checklist
          Row(
            children: [
              _guardChip('1. CONTACT', contactEngaged),
              const SizedBox(width: 6),
              _guardChip('2. LIFT', objectLifted),
              const SizedBox(width: 6),
              _guardChip('3. TRANSIT', transportVerified),
              const SizedBox(width: 6),
              _guardChip('4. RELEASE', releaseConfirmed),
            ],
          ),

          const SizedBox(height: 10),

          // Vision Quality Stats Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DETECTION RATE: ${(detectionRate * 100).toStringAsFixed(0)}% (ROLLING 1S)',
                style: TextStyle(
                  color: detectionRate >= 0.8
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFFB300),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'FRAME AGE: ${frameAgeMs.toStringAsFixed(0)} MS',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guardChip(String title, bool isPassed) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isPassed
              ? const Color(0xFF00E676).withOpacity(0.12)
              : const Color(0xFF1E293B).withOpacity(0.50),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isPassed ? const Color(0xFF00E676) : const Color(0xFF334155),
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isPassed ? const Color(0xFF00E676) : const Color(0xFF64748B),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

