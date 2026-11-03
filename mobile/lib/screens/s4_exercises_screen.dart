import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/storage_service.dart';

class ExercisesScreen extends StatelessWidget {
  final StorageService storageService;
  final Function(ExerciseCode) onSelectExercise;
  final VoidCallback? onLaunchTaskProof;

  const ExercisesScreen({
    super.key,
    required this.storageService,
    required this.onSelectExercise,
    this.onLaunchTaskProof,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = [
      {
        'code': ExerciseCode.fistClench,
        'title': 'Fist Clench & Release',
        'desc': 'Full hand flexion engaging all 5 fingers simultaneously.',
        'channels': 'All 5 Flex Channels',
        'instructions': [
          '1. Begin with hand flat and relaxed on the table.',
          '2. Slowly curl all fingers into a firm fist.',
          '3. Hold the fist position for 0.5s.',
          '4. Smoothly open your hand back to the starting resting pose.',
        ],
        'defaultTarget': '10 reps • 70–100% ROM',
      },
      {
        'code': ExerciseCode.fingerTap,
        'title': 'Single-Finger Tapping',
        'desc': 'Targeted isolated flexion of index finger while other fingers remain resting.',
        'channels': 'Index Flex Channel',
        'instructions': [
          '1. Keep your palm flat and rest non-target fingers.',
          '2. Lift and tap your index finger firmly downward.',
          '3. Repeat with controlled cadence.',
        ],
        'defaultTarget': '15 reps • 65–95% ROM',
      },
      {
        'code': ExerciseCode.pinch,
        'title': 'Thumb-Index Pinch',
        'desc': 'Precision grip bringing thumb tip and index fingertip together.',
        'channels': 'Thumb & Index Flex Channels',
        'instructions': [
          '1. Begin with fingers slightly extended.',
          '2. Bring thumb and index fingertips together into a circle.',
          '3. Squeeze gently for 0.5s.',
          '4. Release back to starting pose.',
        ],
        'defaultTarget': '12 reps • 70–95% ROM',
      },
      {
        'code': ExerciseCode.wristRotation,
        'title': 'Wrist / Forearm Rotation',
        'desc': 'Pronation and supination rotation of the forearm.',
        'channels': 'IMU Gyroscope (Forearm axis)',
        'instructions': [
          '1. Rest forearm on the table with elbow bent 90 degrees.',
          '2. Rotate palm upward, then downward.',
          '3. Move smoothly without jerking.',
        ],
        'defaultTarget': '10 reps • ±60° Rotation',
      },
      {
        'code': ExerciseCode.handControlGame,
        'title': 'Hand Control Challenge',
        'desc': 'Real-time gamified task: flex specific fingers to target bands to catch objects.',
        'channels': 'Target Finger Flex',
        'instructions': [
          '1. Watch the falling target on the screen.',
          '2. Flex the indicated finger to match the target zone height.',
          '3. Catch the object to score points.',
        ],
        'defaultTarget': '15 targets • Game Mode',
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (onLaunchTaskProof != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121715),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'EVENT TASKPROOF',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC8F05F),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        'Camera + Glove',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Object Transfer Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick up object in Zone A, transfer across the boundary, and place steadily into Zone B. Real-time deterministic verdict verification.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF121715),
                      foregroundColor: const Color(0xFFC8F05F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: onLaunchTaskProof,
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Open TaskProof Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'H10 EXERCISE LIBRARY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7A837E), letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
        ],
        ...exercises.map((ex) {
          final code = ex['code'] as ExerciseCode;
          final title = ex['title'] as String;
          final desc = ex['desc'] as String;
          final channels = ex['channels'] as String;
          final target = ex['defaultTarget'] as String;
          final instructions = ex['instructions'] as List<String>;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E7DE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF161C19)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        target,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF121715)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A837E))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121715),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('3-CH ACTIVE', style: TextStyle(color: Color(0xFFC8F05F), fontSize: 8.5, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Channels: $channels',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7A837E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF121715),
                          side: const BorderSide(color: Color(0xFFE2E7DE), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: instructions.map((i) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(i, style: const TextStyle(fontSize: 13)),
                                )).toList(),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                        child: const Text('Instructions', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8F05F),
                          foregroundColor: const Color(0xFF121715),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(0, 44),
                          elevation: 0,
                        ),
                        onPressed: () => onSelectExercise(code),
                        child: const Text('Start Exercise', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
