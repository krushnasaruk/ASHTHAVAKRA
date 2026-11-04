import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/admin_theme.dart';
import 'screens/overview_screen.dart';
import 'screens/live_monitor_screen.dart';
import 'screens/patient_detail_screen.dart';
import 'screens/taskproof_monitor_screen.dart';
import 'screens/audit_export_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const H10ClinicianAdminApp());
}

class H10ClinicianAdminApp extends StatelessWidget {
  const H10ClinicianAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASHTAVAKRA Clinician Admin Monitoring System',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.darkTheme,
      home: const AdminDashboardShell(),
    );
  }
}

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0; // 0: Overview, 1: Live Monitor, 2: TaskProof, 3: Audit & Export
  String? _selectedPatientId;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  void _onSelectPatient(String patientId) {
    setState(() {
      _selectedPatientId = patientId;
    });
  }

  void _onBackFromDetail() {
    setState(() {
      _selectedPatientId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(
        children: [
          // Mandatory Research Prototype Non-Medical Disclaimer Banner
          Container(
            width: double.infinity,
            color: const Color(0xFF1B160C),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 15, color: AdminTheme.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for clinical research and demonstration monitoring. Never diagnose, prescribe, or predict recovery.',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFD38A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Global Clinic Header Bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: AdminTheme.surface,
              border: Border(bottom: BorderSide(color: AdminTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: AdminTheme.lime,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'H10',
                    style: TextStyle(color: AdminTheme.limeDark, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ASHTAVAKRA',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.2,
                            color: AdminTheme.textPrimary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CLINICIAN MONITORING SYSTEM',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1.0,
                            color: AdminTheme.lime,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Biomechanical Hand Rehabilitation • Real-Time Telemetry Supervisor',
                      style: TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),

                // Backend Connectivity Badge
                ListenableBuilder(
                  listenable: _apiService,
                  builder: (context, _) {
                    final connected = _apiService.isConnected;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: connected ? AdminTheme.green.withOpacity(0.15) : AdminTheme.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: connected ? AdminTheme.green : AdminTheme.red, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: connected ? AdminTheme.lime : AdminTheme.red,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            connected ? 'BACKEND 8000 (CONNECTED)' : 'OFFLINE (LOCAL BUFFER)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: connected ? AdminTheme.lime : AdminTheme.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),

                // Clinician Identity Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AdminTheme.cyan,
                        child: Text(
                          'SA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminTheme.limeDark),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Dr. Sarah Adams, PT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Layout: Navigation Rail + Dynamic Screen View
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedPatientId != null ? null : _selectedIndex,
                  backgroundColor: AdminTheme.surface,
                  minWidth: 84,
                  onDestinationSelected: (idx) {
                    setState(() {
                      _selectedIndex = idx;
                      _selectedPatientId = null;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AdminTheme.lime, size: 22),
                  unselectedIconTheme: const IconThemeData(color: AdminTheme.textSecondary, size: 20),
                  selectedLabelTextStyle: const TextStyle(
                    color: AdminTheme.lime,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 10,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.sensors_outlined),
                      selectedIcon: Icon(Icons.sensors),
                      label: Text('Live Cockpit'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.verified_outlined),
                      selectedIcon: Icon(Icons.verified),
                      label: Text('TaskProof™'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment),
                      label: Text('Audit & PDF'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AdminTheme.border),

                // Content View
                Expanded(
                  child: ListenableBuilder(
                    listenable: _apiService,
                    builder: (context, _) {
                      if (_selectedPatientId != null) {
                        return PatientDetailScreen(
                          patientId: _selectedPatientId!,
                          apiService: _apiService,
                          onBack: _onBackFromDetail,
                        );
                      }

                      switch (_selectedIndex) {
                        case 0:
                          return OverviewScreen(
                            apiService: _apiService,
                            onSelectPatient: _onSelectPatient,
                            onOpenLiveMonitor: () => setState(() => _selectedIndex = 1),
                          );
                        case 1:
                          return LiveMonitorScreen(apiService: _apiService);
                        case 2:
                          return const TaskProofMonitorScreen();
                        case 3:
                          return AuditExportScreen(apiService: _apiService);
                        default:
                          return OverviewScreen(
                            apiService: _apiService,
                            onSelectPatient: _onSelectPatient,
                            onOpenLiveMonitor: () => setState(() => _selectedIndex = 1),
                          );
                      }
                    },
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
