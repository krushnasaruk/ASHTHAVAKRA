import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/api_service.dart';

class AuditLogScreen extends StatelessWidget {
  final ApiService apiService;

  const AuditLogScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    final auditLogs = apiService.auditLog;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinical Action Audit Log',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Immutable record of all rehabilitation plan modifications, version increments, and clinical flag reviews.',
            style: TextStyle(fontSize: 13, color: Color(H10Tokens.colorSecondaryText)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                side: const BorderSide(color: Color(H10Tokens.colorBorder)),
              ),
              child: auditLogs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Color(H10Tokens.colorSecondaryText)),
                          SizedBox(height: 12),
                          Text('No clinical actions logged yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Plan edits and flag acknowledgments will appear here in chronological order.', style: TextStyle(fontSize: 12, color: Color(H10Tokens.colorSecondaryText))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: auditLogs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = auditLogs[index];
                        final action = log['action'] as String;
                        final isPlan = action == 'plan_updated';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPlan ? const Color(H10Tokens.colorPrimary) : const Color(H10Tokens.colorWarning),
                            foregroundColor: Colors.white,
                            child: Icon(isPlan ? Icons.edit_note : Icons.check, size: 18),
                          ),
                          title: Text(
                            isPlan
                                ? 'Plan Updated for Patient ${log["patient_id"]} (Version ${log["version"]})'
                                : 'Flag Acknowledged for Patient ${log["patient_id"]} (${log["rule"]})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Clinician: ${log["clinician_id"]} • Justification: "${log["reason"] ?? log["note"] ?? "Reviewed"}"',
                          ),
                          trailing: Text(
                            (log['timestamp'] as String).substring(0, 16).replaceAll('T', ' '),
                            style: const TextStyle(fontSize: 12, color: Color(H10Tokens.colorSecondaryText)),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

