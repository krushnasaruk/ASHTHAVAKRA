import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import 'services/api_service.dart';
import 'screens/overview_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/patient_detail_screen.dart';
import 'screens/audit_log_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const H10ClinicianAdminApp());
}

class H10ClinicianAdminApp extends StatelessWidget {
  const H10ClinicianAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H10 Clinician Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(H10Tokens.colorBackground),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(H10Tokens.colorPrimary),
          primary: const Color(H10Tokens.colorPrimary),
          surface: Colors.white,
        ),
      ),
      home: const ClinicianDashboardShell(),
    );
  }
}

class ClinicianDashboardShell extends StatefulWidget {
  const ClinicianDashboardShell({super.key});

  @override
  State<ClinicianDashboardShell> createState() => _ClinicianDashboardShellState();
}

class _ClinicianDashboardShellState extends State<ClinicianDashboardShell> {
  int _selectedIndex = 0; // 0: Overview, 1: Patients, 2: Audit
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
      body: Column(
        children: [
          // Mandatory Research Prototype Non-Medical Disclaimer Banner
          Container(
            width: double.infinity,
            color: const Color(0xFFFEF3C7), // Amber 100
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for research and demonstration monitoring. Never diagnose, prescribe, or predict clinical recovery.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Global Clinic Header Bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(H10Tokens.colorBorder))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(H10Tokens.colorPrimary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'H10',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Neurological & Hand Rehabilitation Research Clinic',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Clinician Dashboard & Remote Telemetry Portal',
                        style: TextStyle(fontSize: 11, color: Color(H10Tokens.colorSecondaryText)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Backend Connectivity Badge
                ListenableBuilder(
                  listenable: _apiService,
                  builder: (context, _) {
                    final online = _apiService.isConnected;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: online ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: online ? const Color(0xFF81C784) : const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: online ? const Color(H10Tokens.colorSuccess) : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            online ? 'Backend Connected' : 'Offline Mode (Local Telemetry)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: online ? const Color(H10Tokens.colorSuccess) : Colors.black87,
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
                    color: const Color(H10Tokens.colorBackground),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(H10Tokens.colorBorder)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(H10Tokens.colorSecondary),
                        child: Text('SA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Dr. Sarah Adams, PT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Body with Side Navigation Rail
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  backgroundColor: Colors.white,
                  minWidth: 72,
                  onDestinationSelected: (idx) {
                    setState(() {
                      _selectedIndex = idx;
                      _selectedPatientId = null; // Reset patient detail when switching tab
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Color(H10Tokens.colorPrimary)),
                  selectedLabelTextStyle: const TextStyle(
                    color: Color(H10Tokens.colorPrimary),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Color(H10Tokens.colorSecondaryText),
                    fontSize: 11,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Patients'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment),
                      label: Text('Audit Log'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: Color(H10Tokens.colorBorder)),

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
                          );
                        case 1:
                          return PatientListScreen(
                            apiService: _apiService,
                            onSelectPatient: _onSelectPatient,
                          );
                        case 2:
                          return AuditLogScreen(apiService: _apiService);
                        default:
                          return OverviewScreen(
                            apiService: _apiService,
                            onSelectPatient: _onSelectPatient,
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
