import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:h10_core/h10_core.dart';

class PreflightDialog extends StatefulWidget {
  final String backendUrl;

  const PreflightDialog({
    super.key,
    this.backendUrl = 'http://127.0.0.1:8000',
  });

  static Future<void> show(BuildContext context, {String backendUrl = 'http://127.0.0.1:8000'}) {
    return showDialog(
      context: context,
      builder: (_) => PreflightDialog(backendUrl: backendUrl),
    );
  }

  @override
  State<PreflightDialog> createState() => _PreflightDialogState();
}

class _PreflightDialogState extends State<PreflightDialog> {
  bool _isLoading = true;
  String? _error;
  String _overallStatus = 'unknown';
  List<Map<String, dynamic>> _checks = [];

  @override
  void initState() {
    super.initState();
    _fetchPreflight();
  }

  Future<void> _fetchPreflight() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http
          .get(Uri.parse('${widget.backendUrl}/api/preflight'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _overallStatus = data['overall_status'] ?? 'unknown';
          _checks = List<Map<String, dynamic>>.from(data['checks'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Server returned HTTP ${res.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to connect to local backend ($e)';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pass':
        return const Color(H10Tokens.colorSuccess);
      case 'warn':
        return const Color(H10Tokens.colorWarning);
      case 'fail':
        return const Color(H10Tokens.colorError);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pass':
        return Icons.check_circle_outline;
      case 'warn':
        return Icons.warning_amber_rounded;
      case 'fail':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(H10Tokens.radiusCard)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        padding: const EdgeInsets.all(H10Tokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: Color(H10Tokens.colorPrimary), size: 24),
                const SizedBox(width: H10Tokens.space8),
                const Expanded(
                  child: Text(
                    'Preflight System Diagnostics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ],
            ),
            const SizedBox(height: H10Tokens.space8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Demonstration prototype — verifies camera, serial glove, and security boundaries.',
                style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: H10Tokens.space12),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(H10Tokens.colorPrimary)),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 40, color: Color(H10Tokens.colorError)),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(H10Tokens.colorError)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchPreflight,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(H10Tokens.colorPrimary),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _checks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _checks[index];
                    final name = item['name'] ?? 'Check';
                    final status = item['status'] ?? 'unknown';
                    final details = item['details'] ?? '';
                    final hint = item['hint'];
                    final color = _getStatusColor(status);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_getStatusIcon(status), color: color, size: 22),
                          const SizedBox(width: H10Tokens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  details,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                                if (hint != null && hint.toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Hint: $hint',
                                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: color),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: H10Tokens.space12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_overallStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _getStatusColor(_overallStatus).withOpacity(0.3)),
                    ),
                    child: Text(
                      'STATUS: ${_overallStatus.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _getStatusColor(_overallStatus),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _fetchPreflight,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Rerun checks',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
