import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class SyncService {
  final StorageService storageService;
  String backendBaseUrl;
  bool isSyncing = false;

  SyncService({
    required this.storageService,
    this.backendBaseUrl = 'http://127.0.0.1:8000',
  });

  Future<void> syncPendingSessions() async {
    if (isSyncing) return;
    isSyncing = true;

    try {
      final pendingSessions = storageService.sessions.where((s) => s.syncStatus == 'pending').toList();
      for (final s in pendingSessions) {
        final url = Uri.parse('$backendBaseUrl/api/v1/sessions');
        try {
          final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(s.toJson()),
          ).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200 || res.statusCode == 201) {
            storageService.markSessionSynced(s.id);
          } else if (res.statusCode == 409) {
            storageService.markSessionConflict(s.id);
          }
        } catch (_) {
          // Network failure: keep pending for next retry
        }
      }
    } finally {
      isSyncing = false;
    }
  }
}
