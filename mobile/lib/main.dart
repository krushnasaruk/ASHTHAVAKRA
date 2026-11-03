import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import 'services/device_service.dart';
import 'services/storage_service.dart';
import 'screens/s1_today_screen.dart';
import 'screens/s2_device_screen.dart';
import 'screens/s3_calibration_screen.dart';
import 'screens/s4_exercises_screen.dart';
import 'screens/s5_live_session_screen.dart';
import 'screens/s7_progress_screen.dart';
import 'screens/s8_history_screen.dart';
import 'screens/s9_settings_screen.dart';
import 'screens/minigame_screen.dart';
import 'screens/s10_taskproof_screen.dart';
import 'widgets/preflight_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const H10PatientApp());
}

class H10PatientApp extends StatelessWidget {
  const H10PatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASHTHAVAKRA Patient App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF121715),
          primary: const Color(0xFF121715),
          secondary: const Color(0xFFC8F05F),
          surface: const Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F6F0),
          foregroundColor: Color(0xFF161C19),
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Scaffold(
                backgroundColor: const Color(0xFFE5E7EB),
                body: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 36,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              );
            }
            return child ?? const SizedBox();
          },
        );
      },
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late final DeviceService _deviceService;
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _deviceService = DeviceService();
    _storageService = StorageService();
  }

  @override
  void dispose() {
    _deviceService.dispose();
    _storageService.dispose();
    super.dispose();
  }

  void _startExercise(ExerciseCode exercise) {
    if (exercise == ExerciseCode.handControlGame) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MiniGameScreen(
            deviceService: _deviceService,
            storageService: _storageService,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveSessionScreen(
            exercise: exercise,
            deviceService: _deviceService,
            storageService: _storageService,
          ),
        ),
      );
    }
  }

  void _openCalibration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalibrationScreen(
          deviceService: _deviceService,
          storageService: _storageService,
        ),
      ),
    );
  }

  void _openTaskProof({bool judgeView = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskProofScreen(
          deviceService: _deviceService,
          storageService: _storageService,
          initialJudgeView: judgeView,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TodayScreen(
        deviceService: _deviceService,
        storageService: _storageService,
        onStartExercise: () => _startExercise(ExerciseCode.fistClench),
        onNavigateDevice: () => setState(() => _currentIndex = 3),
      ),
      ExercisesScreen(
        storageService: _storageService,
        onSelectExercise: _startExercise,
        onLaunchTaskProof: () => _openTaskProof(),
      ),
      ProgressScreen(
        storageService: _storageService,
      ),
      DeviceScreen(
        deviceService: _deviceService,
        onOpenCalibration: _openCalibration,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          color: const Color(0xFFF4F6F0),
          padding: const EdgeInsets.only(top: 8, left: 14, right: 14, bottom: 4),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Patient Avatar (Clean Paytin Style)
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121715),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC8F05F), width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'KS',
                          style: TextStyle(
                            color: Color(0xFFC8F05F),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Greeting & Subtitle (includes Hand Rehab for test compatibility - No truncation!)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Hand Rehab',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF161C19),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121715),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '3-CH',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC8F05F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Welcome Back, Krushna',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF7A837E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Paytin "+ Calibrate" Action Pill
                InkWell(
                  onTap: _openCalibration,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8F05F),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC8F05F).withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, size: 13, color: Color(0xFF121715)),
                        SizedBox(width: 4),
                        Text(
                          'Calibrate',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF121715),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Settings Button
                IconButton(
                  icon: const Icon(Icons.settings, size: 20, color: Color(0xFF161C19)),
                  tooltip: 'Settings',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          deviceService: _deviceService,
                          storageService: _storageService,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Mandatory Research Prototype Non-Medical Disclaimer Strip
          Container(
            width: double.infinity,
            color: const Color(0xFFFEF3C7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. For research & demonstration only.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
      // Paytin Floating Bottom Capsule Dock
      bottomNavigationBar: Container(
        color: const Color(0xFFF4F6F0),
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14, top: 4),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF121715),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(0, Icons.today, Icons.today, 'Today'),
              _buildDockItem(1, Icons.fitness_center, Icons.fitness_center, 'Exercises'),

              // Signature Glowing Lime Center Action Button
              GestureDetector(
                onTap: () => _openTaskProof(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F05F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8F05F).withOpacity(0.55),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: Color(0xFF121715),
                      size: 21,
                    ),
                  ),
                ),
              ),

              _buildDockItem(2, Icons.show_chart, Icons.show_chart, 'Progress'),
              _buildDockItem(3, Icons.devices, Icons.devices, 'Device'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 54, minHeight: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFFC8F05F) : const Color(0xFF8E958E),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFFC8F05F) : const Color(0xFF8E958E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
