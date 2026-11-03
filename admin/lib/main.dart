import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const H10ClinicianAdminApp());
}

class H10ClinicianAdminApp extends StatelessWidget {
  const H10ClinicianAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H10 Clinician Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0F0E), // Obsidian dark background
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF141A17),
          primary: Color(0xFFC8F05F),
          secondary: Color(0xFFC8F05F),
          onSurface: Colors.white,
          onPrimary: Color(0xFF0B0F0E),
        ),
      ),
      home: const AdminDashboardScratchShell(),
    );
  }
}

class AdminDashboardScratchShell extends StatefulWidget {
  const AdminDashboardScratchShell({super.key});

  @override
  State<AdminDashboardScratchShell> createState() => _AdminDashboardScratchShellState();
}

class _AdminDashboardScratchShellState extends State<AdminDashboardScratchShell> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F0E),
      body: SafeArea(
        child: Column(
          children: [
            // Mandatory Research Prototype Non-Medical Disclaimer Banner
            Container(
              width: double.infinity,
              color: const Color(0xFF1B160C),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFFF5A623)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for research and engineering demonstration.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD38A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fresh Blank Slate Canvas Ready for Building from Scratch
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A17),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF232D28), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.dashboard_customize_outlined,
                          color: Color(0xFFC8F05F),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ADMIN DASHBOARD',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clean slate ready to build from scratch.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A837E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
