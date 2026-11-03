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
      padding: const EdgeInsets.all(H10Tokens.space16),
      children: [
        if (onLaunchTaskProof != null) ...[
          Card(
            color: const Color(0xFFF0FDF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(H10Tokens.colorPrimary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EVENT TASKPROOF',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      const Chip(
                        label: Text('Camera + Glove', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        visualDensity: VisualDensity.compact,
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
                    style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(H10Tokens.colorPrimary),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onLaunchTaskProof,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Open TaskProof Verification'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),
          const Text(
            'H10 EXERCISE LIBRARY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
          ),
          const SizedBox(height: H10Tokens.space12),
        ],
        ...exercises.map((ex) {
          final code = ex['code'] as ExerciseCode;
          final title = ex['title'] as String;
          final desc = ex['desc'] as String;
          final channels = ex['channels'] as String;
          final target = ex['defaultTarget'] as String;
          final instructions = ex['instructions'] as List<String>;

        return Card(
          color: const Color(H10Tokens.colorCard),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
            side: const BorderSide(color: Color(H10Tokens.colorBorder)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(H10Tokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(H10Tokens.colorSurfaceTint),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        target,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 13, color: Color(H10Tokens.colorSecondaryText))),
                const SizedBox(height: 8),
                Text('Channels: $channels', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(H10Tokens.colorSecondaryText))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(title),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: instructions.map((i) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(i),
                                )).toList(),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                        child: const Text('Instructions', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(H10Tokens.colorPrimary),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => onSelectExercise(code),
                        child: const Text('Start Exercise', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}
}
