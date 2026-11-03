import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../widgets/preflight_dialog.dart';

class TaskProofScreen extends StatefulWidget {
  final DeviceService deviceService;
  final StorageService storageService;
  final String backendHost;
  final int backendPort;
  final bool initialJudgeView;

  const TaskProofScreen({
    super.key,
    required this.deviceService,
    required this.storageService,
    this.backendHost = '127.0.0.1',
    this.backendPort = 8000,
    this.initialJudgeView = false,
  });

  @override
  State<TaskProofScreen> createState() => _TaskProofScreenState();
}

class _TaskProofScreenState extends State<TaskProofScreen> {
  bool _isJudgeView = false;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;

  // TaskProof Engine Live State
  String _currentState = 'READY';
  String _verdict = 'NOT_STARTED';
  List<String> _reasonCodes = [];
  String _attemptId = '';
  double _elapsedSeconds = 0.0;
  Timer? _stopwatchTimer;
  DateTime? _attemptStartTime;

  // Vision telemetry
  bool _markerDetected = false;
  String _currentZone = 'none';
  double _detectionRate = 0.0;
  double _frameAgeMs = 0.0;

  // Sensor telemetry
  bool _contactOn = false;
  bool _gripChanged = false;
  List<double> _flexValues = [0, 0, 0];

  // Attempt history
  final List<Map<String, dynamic>> _lastAttempts = [];

  // Connection info
  bool _isWsConnected = false;
  String? _wsError;

  // Hotkey / Ground truth feedback message
  String? _operatorFeedback;
  Timer? _feedbackTimer;

  final List<String> _statesFlow = [
    'READY',
    'SOURCE_VISIBLE',
    'CONTACT_CANDIDATE',
    'OBJECT_LIFTED',
    'TARGET_REACHED',
    'RELEASE_CONFIRMED',
    'VERIFIED',
  ];

  @override
  void initState() {
    super.initState();
    _isJudgeView = widget.initialJudgeView;
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      final wsUrl = Uri.parse('ws://${widget.backendHost}:${widget.backendPort}/ws/live');
      _wsChannel = WebSocketChannel.connect(wsUrl);
      _wsSub = _wsChannel!.stream.listen(
        (data) {
          if (!_isWsConnected) {
            setState(() {
              _isWsConnected = true;
              _wsError = null;
            });
          }
          _processLiveFrame(data);
        },
        onError: (err) {
          setState(() {
            _isWsConnected = false;
            _wsError = 'WebSocket disconnected ($err)';
          });
          _scheduleReconnect();
        },
        onDone: () {
          setState(() {
            _isWsConnected = false;
          });
          _scheduleReconnect();
        },
      );
    } catch (e) {
      setState(() {
        _isWsConnected = false;
        _wsError = 'Connection failed ($e)';
      });
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isWsConnected) {
        _connectWebSocket();
      }
    });
  }

  void _processLiveFrame(dynamic raw) {
    try {
      final jsonMap = json.decode(raw.toString());
      final tp = jsonMap['taskproof'];
      final vis = jsonMap['vision'];
      final sens = jsonMap['sensor'];

      if (mounted) {
        setState(() {
          if (tp != null) {
            final oldState = _currentState;
            _currentState = tp['state'] ?? 'READY';
            final newVerdict = tp['verdict'] ?? 'NOT_STARTED';

            if (_currentState != 'READY' && oldState == 'READY') {
              _attemptStartTime = DateTime.now();
              _startTimer();
            } else if (newVerdict != 'NOT_STARTED' && _verdict == 'NOT_STARTED') {
              _stopTimer();
              _recordAttempt(newVerdict);
            }
            _verdict = newVerdict;
            _reasonCodes = List<String>.from(tp['reason_codes'] ?? []);
            _attemptId = tp['attempt_id'] ?? '';
          }

          if (vis != null) {
            _markerDetected = vis['detected'] ?? false;
            _currentZone = vis['zone'] ?? 'none';
            _detectionRate = (vis['detection_rate_1s'] ?? 0.0).toDouble();
            _frameAgeMs = (vis['frame_age_ms'] ?? 0.0).toDouble();
          }

          if (sens != null) {
            _contactOn = sens['contact_on'] ?? false;
            _gripChanged = sens['grip_change'] ?? false;
            if (sens['flex'] != null) {
              final fList = List<num>.from(sens['flex']);
              _flexValues = fList.map((n) => (n / 327.67).clamp(0.0, 100.0)).toList();
            }
          }
        });
      }
    } catch (_) {}
  }

  void _startTimer() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_attemptStartTime != null && mounted) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_attemptStartTime!).inMilliseconds / 1000.0;
        });
      }
    });
  }

  void _stopTimer() {
    _stopwatchTimer?.cancel();
  }

  void _recordAttempt(String verdict) {
    if (_lastAttempts.length >= 5) {
      _lastAttempts.removeAt(0);
    }
    _lastAttempts.add({
      'id': _attemptId.isNotEmpty ? _attemptId : 'att_${DateTime.now().millisecondsSinceEpoch % 1000}',
      'verdict': verdict,
      'duration': _elapsedSeconds,
      'time': DateTime.now(),
    });
  }

  Future<void> _startNewAttempt() async {
    try {
      final res = await http.post(
        Uri.parse('http://${widget.backendHost}:${widget.backendPort}/api/tasks/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': 'sess_${DateTime.now().millisecondsSinceEpoch}',
          'attempt_index': _lastAttempts.length + 1,
        }),
      );
      if (res.statusCode == 200) {
        setState(() {
          _verdict = 'NOT_STARTED';
          _currentState = 'READY';
          _reasonCodes = [];
          _elapsedSeconds = 0.0;
          _attemptStartTime = DateTime.now();
        });
        _startTimer();
      }
    } catch (e) {
      _showFeedback('Failed to start attempt: $e');
    }
  }

  Future<void> _submitGroundTruth(String label) async {
    if (_attemptId.isEmpty) {
      _showFeedback('No active attempt to label');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('http://${widget.backendHost}:${widget.backendPort}/api/tasks/$_attemptId/ground-truth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'attempt_id': _attemptId,
          'label': label,
          'marker_source': 'mobile_operator_key',
          'labeller_pseudonym': 'operator_mobile',
        }),
      );
      if (res.statusCode == 200) {
        _showFeedback('Label "$label" recorded');
      } else {
        _showFeedback('Error ${res.statusCode} recording label');
      }
    } catch (e) {
      _showFeedback('Network error: $e');
    }
  }

  Future<void> _abortAttempt() async {
    if (_attemptId.isEmpty) return;
    try {
      await http.post(
        Uri.parse('http://${widget.backendHost}:${widget.backendPort}/api/tasks/$_attemptId/abort'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reason': 'Operator aborted from Mobile UI'}),
      );
      _showFeedback('Attempt aborted');
    } catch (e) {
      _showFeedback('Abort error: $e');
    }
  }

  void _showFeedback(String msg) {
    setState(() {
      _operatorFeedback = msg;
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _operatorFeedback = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    _stopwatchTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict) {
      case 'VERIFIED':
        return const Color(0xFF16A34A); // Green
      case 'FAILED':
        return const Color(0xFFDC2626); // Red
      case 'UNCERTAIN':
        return const Color(0xFF9333EA); // Purple
      case 'ABORTED':
        return const Color(0xFFEA580C); // Orange
      case 'NOT_STARTED':
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEXUS Object Transfer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 3,
                  backgroundColor: _isWsConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _isWsConnected ? '25 Hz Live Link' : 'Offline Mode',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Preflight Diagnostics',
            onPressed: () => PreflightDialog.show(context),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_isJudgeView ? 'Judge' : 'Operator'),
              selected: _isJudgeView,
              onSelected: (val) => setState(() => _isJudgeView = val),
              selectedColor: const Color(H10Tokens.colorPrimary).withOpacity(0.2),
            ),
          ),
        ],
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
                    'NON-MEDICAL DEVICE — Research Prototype for Innovation 2K26. Never for clinical diagnosis.',
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
          if (!_isWsConnected && _wsError != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFEE2E2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                'LIVE LINK: $_wsError (Start server or run simulator)',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                textAlign: TextAlign.center,
              ),
            ),
          if (_operatorFeedback != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFE0E7FF),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _operatorFeedback!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _isJudgeView ? _buildJudgeView() : _buildOperatorView(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // JUDGE VIEW (High-Contrast, Verdict-First)
  // ==========================================
  Widget _buildJudgeView() {
    final vColor = _getVerdictColor(_verdict);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(H10Tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Big Verdict Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: vColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              border: Border.all(color: vColor, width: 3),
            ),
            child: Column(
              children: [
                Text(
                  'TASK VERDICT',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w800,
                    color: vColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _verdict.replaceAll('_', ' '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: vColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: vColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_elapsedSeconds.toStringAsFixed(1)} s',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: vColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // Attempt Context & Reason Codes
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VERIFICATION EVIDENCE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transfer Target:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      const Text('Zone A  ➔  Zone B', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Object Marker:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      Text(
                        _markerDetected ? 'ArUco DICT_4X4_50 (Tracked)' : 'No Marker Detected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _markerDetected ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorError),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Location:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                      Text(_currentZone.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_reasonCodes.isNotEmpty) ...[
                    const Divider(height: 20),
                    const Text('Reason Codes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _reasonCodes
                          .map(
                            (rc) => Chip(
                              label: Text(rc, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFFF1F5F9),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // Last 5 Attempts Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECENT ATTEMPTS (LAST 5)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  if (_lastAttempts.isEmpty)
                    const Text('No attempts recorded in this session yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    Column(
                      children: _lastAttempts.reversed.map((att) {
                        final color = _getVerdictColor(att['verdict']);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(att['id'], style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: color.withOpacity(0.4)),
                                ),
                                child: Text(
                                  att['verdict'],
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${(att['duration'] as double).toStringAsFixed(1)}s', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OPERATOR VIEW (Full Controls & Telemetry)
  // ==========================================
  Widget _buildOperatorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(H10Tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 7-State Stepper Progress
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TASKPROOF STATE MACHINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statesFlow.length,
                      separatorBuilder: (_, __) => const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                      itemBuilder: (context, i) {
                        final st = _statesFlow[i];
                        final isCurrent = st == _currentState;
                        final isPast = _statesFlow.indexOf(_currentState) > i;
                        final color = isCurrent
                            ? const Color(H10Tokens.colorPrimary)
                            : isPast
                                ? const Color(H10Tokens.colorSuccess)
                                : Colors.grey;

                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrent ? color.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: isCurrent ? Border.all(color: color, width: 1.5) : null,
                            ),
                            child: Text(
                              st.replaceAll('_', '\n'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space12),

          // Vision & Kinematic Telemetry Gauges
          Row(
            children: [
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                    side: const BorderSide(color: Color(H10Tokens.colorBorder)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VISION TRACKER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Zone: ${_currentZone.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Rate: ${(_detectionRate * 100).toStringAsFixed(0)}% (1s)', style: const TextStyle(fontSize: 11)),
                        Text('Age: ${_frameAgeMs.toStringAsFixed(0)} ms', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
                    side: const BorderSide(color: Color(H10Tokens.colorBorder)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GLOVE CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: _contactOn ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(_contactOn ? 'FSR CONTACT ON' : 'NO CONTACT', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Grip: ${_gripChanged ? "GRIP DELTA ≥15%" : "BASELINE"}', style: const TextStyle(fontSize: 11)),
                        Text('Channels: ${_flexValues.length} Flex + IMU', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: H10Tokens.space16),

          // Ground Truth Labelling Controls
          const Text('OPERATOR LABELLING (GROUND TRUTH)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _submitGroundTruth('success'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('[S] Success'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _submitGroundTruth('fail'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('[F] Fail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _submitGroundTruth('uncertain'),
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('[U] Uncertain'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9333EA),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _abortAttempt,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('[Esc] Abort'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEA580C),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: H10Tokens.space16),

          // Action Buttons: New Attempt, CSV Export
          ElevatedButton.icon(
            onPressed: _startNewAttempt,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start New Attempt [N]'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(H10Tokens.colorPrimary),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
