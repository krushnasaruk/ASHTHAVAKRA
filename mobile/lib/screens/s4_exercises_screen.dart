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
        'target': '10 reps • 70–100% ROM',
      },
      {
        'code': ExerciseCode.fingerTap,
        'title': 'Single-Finger Tapping',
        'desc': 'Targeted isolated flexion of index finger.',
        'target': '15 reps • 65–95% ROM',
      },
      {
        'code': ExerciseCode.pinch,
        'title': 'Thumb-Index Pinch',
        'desc': 'Precision grip bringing thumb and index fingertips together.',
        'target': '12 reps • 70–95% ROM',
      },
      {
        'code': ExerciseCode.wristRotation,
        'title': 'Wrist / Forearm Rotation',
        'desc': 'Pronation and supination rotation of the forearm.',
        'target': '10 reps • ±60°',
      },
      {
        'code': ExerciseCode.handControlGame,
        'title': 'Hand Control Challenge',
        'desc': 'Real-time gamified task: flex specific fingers to catch objects.',
        'target': 'Game Mode',
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      children: [
        if (onLaunchTaskProof != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2822),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TASKPROOF EVENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC8F05F),
                        ),
                      ),
                    ),
                    const Icon(Icons.verified_outlined, size: 18, color: Color(0xFFC8F05F)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Object Transfer Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8F05F),
                      foregroundColor: const Color(0xFF0B0F0E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: onLaunchTaskProof,
                    child: const Text('Open TaskProof Verification', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Exercise Library',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
        ],
        ...exercises.map((ex) {
          final code = ex['code'] as ExerciseCode;
          final title = ex['title'] as String;
          final desc = ex['desc'] as String;
          final target = ex['target'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2822),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        target,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFC8F05F)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 12.5, color: Color(0xFF8E958E))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8F05F),
                      foregroundColor: const Color(0xFF0B0F0E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    onPressed: () => onSelectExercise(code),
                    child: const Text('Start Routine', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }
}
