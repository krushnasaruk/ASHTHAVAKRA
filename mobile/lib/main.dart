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
      title: 'H10 Patient App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(H10Tokens.colorPrimary),
          primary: const Color(H10Tokens.colorPrimary),
          surface: const Color(H10Tokens.colorCard),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(H10Tokens.colorCard),
          foregroundColor: Color(H10Tokens.colorText),
          elevation: 1,
        ),
      ),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Scaffold(
                backgroundColor: const Color(0xFFF1F5F9),
                body: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: BoxDecoration(
                      color: const Color(H10Tokens.colorBackground),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(H10Tokens.colorPrimary).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'H10',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(H10Tokens.colorPrimary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Hand Rehab',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(H10Tokens.colorPrimary),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'v1',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: _deviceService,
            builder: (context, _) {
              final isStreaming = _deviceService.state == DeviceConnectionState.streaming;
              final isConnected = _deviceService.state == DeviceConnectionState.connected;
              final color = isStreaming
                  ? const Color(H10Tokens.colorSuccess)
                  : isConnected
                      ? const Color(H10Tokens.colorInfo)
                      : const Color(H10Tokens.colorError);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Chip(
                  avatar: CircleAvatar(backgroundColor: color, radius: 4),
                  label: Text(
                    _deviceService.state.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Preflight Diagnostics',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => PreflightDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Session History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(storageService: _storageService),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
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
      body: Column(
        children: [
          // Mandatory Research Prototype Non-Medical Disclaimer Strip
          Container(
            width: double.infinity,
            color: const Color(0xFFFEF3C7), // Amber 100
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Device',
          ),
        ],
      ),
    );
  }
}
