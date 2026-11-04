import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/admin_theme.dart';
import 'screens/overview_screen.dart';
import 'screens/live_monitor_screen.dart';
import 'screens/patient_detail_screen.dart';
import 'screens/taskproof_monitor_screen.dart';
import 'screens/audit_export_screen.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_top_bar.dart';
import 'widgets/mobile_app_bar.dart';
import 'widgets/floating_dock.dart';
import 'widgets/plan_editor_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const H10ClinicianAdminApp());
}

class H10ClinicianAdminApp extends StatelessWidget {
  const H10ClinicianAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASHTAVAKRA Clinician Monitoring System',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
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
  int _selectedIndex = 0; // 0: Today/Overview, 1: Live HUD, 2: TaskProof, 3: Audit & Export
  String? _selectedPatientId;
  bool _isWidescreenMode = true; // Laptop Widescreen Dashboard by default
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

  void _openPrescriptionModal() {
    final activePatient = _selectedPatientId ?? 'P-014';
    final plan = _apiService.getPatientActivePlan(activePatient);
    PlanEditorDialog.show(
      context,
      patientId: activePatient,
      currentPlan: plan,
      apiService: _apiService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePatient = _selectedPatientId ?? 'P-014';

    Widget currentBody;
    if (_selectedPatientId != null) {
      currentBody = PatientDetailScreen(
        patientId: _selectedPatientId!,
        apiService: _apiService,
        onBack: _onBackFromDetail,
      );
    } else {
      switch (_selectedIndex) {
        case 0:
          currentBody = OverviewScreen(
            apiService: _apiService,
            onSelectPatient: _onSelectPatient,
            onOpenLiveMonitor: () => setState(() => _selectedIndex = 1),
            onOpenTaskProof: () => setState(() => _selectedIndex = 2),
          );
          break;
        case 1:
          currentBody = LiveMonitorScreen(
            apiService: _apiService,
            initialPatientId: activePatient,
          );
          break;
        case 2:
          currentBody = const TaskProofMonitorScreen();
          break;
        case 3:
          currentBody = AuditExportScreen(
            apiService: _apiService,
          );
          break;
        default:
          currentBody = OverviewScreen(
            apiService: _apiService,
            onSelectPatient: _onSelectPatient,
            onOpenLiveMonitor: () => setState(() => _selectedIndex = 1),
            onOpenTaskProof: () => setState(() => _selectedIndex = 2),
          );
      }
    }

    // Disclaimer Banner
    final disclaimerBanner = Container(
      width: double.infinity,
      color: const Color(0xFF1B160C),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
      child: const Text(
        'PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for clinical research and demonstration monitoring. Never diagnose, prescribe, or predict recovery.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          color: Color(0xFFFFD38A),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        // Desktop Widescreen Layout (Matching the user's reference image exactly)
        if (isDesktop && _isWidescreenMode) {
          return Scaffold(
            backgroundColor: AdminTheme.canvasBg,
            body: SafeArea(
              child: Row(
                children: [
                  // 1. Fixed Left Sidebar (Dark slate with neon lime active pill)
                  DashboardSidebar(
                    selectedIndex: _selectedPatientId != null ? -1 : _selectedIndex,
                    onSelectTab: (idx) {
                      setState(() {
                        _selectedIndex = idx;
                        _selectedPatientId = null;
                      });
                    },
                    onOpenPrescription: _openPrescriptionModal,
                  ),

                  // 2. Right Main Dashboard Canvas
                  Expanded(
                    child: Column(
                      children: [
                        disclaimerBanner,
                        DashboardTopBar(
                          clinicianName: 'Dr. Sarah Chen',
                          onPrescribe: _openPrescriptionModal,
                        ),
                        Expanded(
                          child: ListenableBuilder(
                            listenable: _apiService,
                            builder: (context, _) => currentBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Mobile / Compact Layout Fallback
        return Scaffold(
          backgroundColor: const Color(0xFF0B0F0E),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    disclaimerBanner,
                    MobileAppBar(
                      patientId: activePatient,
                      isWidescreenMode: _isWidescreenMode,
                      onToggleWidescreen: () {
                        setState(() => _isWidescreenMode = !_isWidescreenMode);
                      },
                      onActionTap: _openPrescriptionModal,
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _apiService,
                        builder: (context, _) => currentBody,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 8,
                  child: Center(
                    child: FloatingBottomDock(
                      selectedIndex: _selectedPatientId != null ? -1 : _selectedIndex,
                      onSelectTab: (idx) {
                        setState(() {
                          _selectedIndex = idx;
                          _selectedPatientId = null;
                        });
                      },
                      onCenterTap: () {
                        setState(() {
                          _selectedIndex = 1;
                          _selectedPatientId = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
