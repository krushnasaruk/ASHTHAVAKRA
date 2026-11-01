import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/api_service.dart';

class PatientListScreen extends StatefulWidget {
  final ApiService apiService;
  final Function(String patientId) onSelectPatient;

  const PatientListScreen({
    super.key,
    required this.apiService,
    required this.onSelectPatient,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String _searchQuery = '';
  String _sideFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final allPatients = widget.apiService.patients;
    final flags = widget.apiService.flags;

    final filtered = allPatients.where((p) {
      final matchesQuery = p.pseudonym.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSide = _sideFilter == 'all' || p.affectedHand.toLowerCase() == _sideFilter;
      return matchesQuery && matchesSide;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enrolled Research Cohort',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Search, filter, and review active patient baseline data and rehabilitation trajectory.',
                    style: TextStyle(fontSize: 13, color: Color(H10Tokens.colorSecondaryText)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(H10Tokens.colorBorder)),
                ),
                child: Text(
                  '${filtered.length} Patients Displayed',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Toolbar
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search by patient ID (e.g. P-014) or rehabilitation goal...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(H10Tokens.colorBorder)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sideFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Affected Sides')),
                      DropdownMenuItem(value: 'left', child: Text('Left Side')),
                      DropdownMenuItem(value: 'right', child: Text('Right Side')),
                      DropdownMenuItem(value: 'bilateral', child: Text('Bilateral')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sideFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Patients Table
          Expanded(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                side: const BorderSide(color: Color(H10Tokens.colorBorder)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Patient ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Affected Hand', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Baseline Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Rehabilitation Goal', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Open Flags', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((p) {
                      final openFlagCount = flags.where((f) => f.patientId == p.pseudonym && !f.isAcknowledged).length;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(p.pseudonym, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary))),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(H10Tokens.colorSurfaceTint).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.affectedHand.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          DataCell(
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 14, color: Color(H10Tokens.colorSuccess)),
                                SizedBox(width: 4),
                                Text(
                                  'Established (72.5%)',
                                  style: TextStyle(fontSize: 12, color: Color(H10Tokens.colorSuccess)),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 320,
                              child: Text(
                                p.notes.isNotEmpty ? p.notes : 'Active motor rehabilitation',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            openFlagCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$openFlagCount Alert${openFlagCount > 1 ? "s" : ""}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorError)),
                                    ),
                                  )
                                : const Text('0', style: TextStyle(color: Color(H10Tokens.colorSecondaryText))),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text('View Detail'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(H10Tokens.colorPrimary),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => widget.onSelectPatient(p.pseudonym),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
