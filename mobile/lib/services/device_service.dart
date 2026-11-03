import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:h10_core/h10_core.dart';

enum DeviceConnectionState {
  idle,
  validating,
  connecting,
  connected,
  streaming,
  degraded,
  reconnecting,
  disconnected,
}

enum ConnectionMode { esp32, simulator }

class DeviceService extends ChangeNotifier {
  ConnectionMode mode = ConnectionMode.simulator;
  String host = '127.0.0.1';
  int port = 8000; // Simulator default port
  DeviceConnectionState state = DeviceConnectionState.idle;

  final PacketDecoder decoder = PacketDecoder();
  final SessionQualityGate qualityGate = const SessionQualityGate();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  Timer? _degradedTimer;
  Timer? _rateTimer;

  int packetCountInLastSec = 0;
  int currentPacketRateHz = 0;
  int lastPacketTimeMs = 0;
  int lastPacketAgeMs = 0;
  bool isSimulated = true;
  int batteryPct = 100;
  bool isUsbPowered = true;
  String batteryStatus = 'USB Powered (5V VBUS)';
  bool isCalibrated = true;

  // Hardware Metadata (Competition Profile vs Platform)
  String hardwareProfile = 'demo3'; // 'demo3' (3 flex + FSR + IMU) or 'full5'
  String controllerModel = 'ESP32-S3 N16R8';
  String adcModel = 'ADS1115 16-bit (I2C 0x48)';
  String imuModel = 'MPU6050 6-DOF (I2C 0x68)';
  bool adcOk = true;
  bool fsrOk = true;
  bool imuOk = true;
  int baudRate = 921600;

  void toggleHardwareProfile() {
    hardwareProfile = (hardwareProfile == 'demo3') ? 'full5' : 'demo3';
    notifyListeners();
  }

  SensorPacket? latestPacket;
  List<double> latestNormalizedFlex = [0, 0, 0, 0, 0];
  String currentDataQuality = 'good';
  String? lastValidationError;

  CalibrationRecord? activeCalibration;

  DeviceService() {
    // 1-second ticker for stream rate and packet age
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentPacketRateHz = packetCountInLastSec;
      packetCountInLastSec = 0;
      if (lastPacketTimeMs > 0) {
        lastPacketAgeMs = DateTime.now().millisecondsSinceEpoch - lastPacketTimeMs;
        if (lastPacketAgeMs > 1000 && state == DeviceConnectionState.streaming) {
          state = DeviceConnectionState.degraded;
          notifyListeners();
        }
      }
      notifyListeners();
    });
  }

  void setMode(ConnectionMode newMode) {
    mode = newMode;
    if (mode == ConnectionMode.simulator) {
      host = '127.0.0.1';
      port = 8000;
    } else {
      host = '192.168.4.1';
      port = 80;
    }
    notifyListeners();
  }

  /// Step-by-step IP and device validation.
  Future<bool> validateAndConnect(String targetHost, int targetPort) async {
    host = targetHost.trim();
    port = targetPort;
    state = DeviceConnectionState.validating;
    lastValidationError = null;
    notifyListeners();

    final baseHttp = 'http://$host:$port';

    try {
      // Step 1: Reachability & Info check
      final infoUrl = Uri.parse('$baseHttp/api/info');
      final res = await http.get(infoUrl).timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) {
        lastValidationError = 'HTTP API unavailable (status ${res.statusCode})';
        state = DeviceConnectionState.disconnected;
        notifyListeners();
        return false;
      }

      final infoData = jsonDecode(res.body);
      final data = infoData['data'] ?? {};
      final protocol = data['protocol'] as int? ?? 0;
      if (protocol != 1) {
        lastValidationError = 'Protocol unsupported (device protocol $protocol, required 1)';
        state = DeviceConnectionState.disconnected;
        notifyListeners();
        return false;
      }

      isSimulated = data['simulated'] as bool? ?? (mode == ConnectionMode.simulator);

      // Step 2: Open WebSocket stream
      await connectStream();
      return true;
    } catch (e) {
      lastValidationError = 'Device unreachable: ${e.toString().split('\n').first}';
      state = DeviceConnectionState.disconnected;
      notifyListeners();
      return false;
    }
  }

  Future<void> connectStream() async {
    state = DeviceConnectionState.connecting;
    notifyListeners();

    final wsUrl = Uri.parse('ws://$host:$port/ws/sensors');
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      state = DeviceConnectionState.connected;
      notifyListeners();

      _channelSub = _channel!.stream.listen(
        (data) => _handleIncomingData(data),
        onError: (err) {
          state = DeviceConnectionState.disconnected;
          notifyListeners();
        },
        onDone: () {
          state = DeviceConnectionState.disconnected;
          notifyListeners();
        },
      );
    } catch (e) {
      state = DeviceConnectionState.disconnected;
      lastValidationError = 'WebSocket connection failed: $e';
      notifyListeners();
    }
  }

  void _handleIncomingData(dynamic data) {
    try {
      SensorPacket packet;
      if (data is Uint8List) {
        packet = decoder.decodeBinary(data);
      } else if (data is List<int>) {
        packet = decoder.decodeBinary(Uint8List.fromList(data));
      } else if (data is String) {
        // First message may be hello frame
        if (data.contains('"type":"hello"') || data.contains('"type": "hello"')) {
          final hello = jsonDecode(data);
          if (hello['protocol'] != 1) {
            disconnect();
            lastValidationError = 'Incompatible protocol in hello frame';
            return;
          }
          state = DeviceConnectionState.streaming;
          notifyListeners();
          return;
        }
        packet = decoder.decodeJson(data);
      } else {
        return;
      }

      latestPacket = packet;
      batteryPct = packet.batteryPct;
      isCalibrated = packet.isCalibrated;
      isSimulated = packet.isSimulated || isSimulated;
      lastPacketTimeMs = DateTime.now().millisecondsSinceEpoch;
      packetCountInLastSec++;

      if (state != DeviceConnectionState.streaming) {
        state = DeviceConnectionState.streaming;
      }

      // Live normalization if calibration exists
      if (activeCalibration != null && activeCalibration!.isValid) {
        latestNormalizedFlex = Normalizer.normalizeAll(
          rawFlex: packet.flex,
          calibration: activeCalibration!,
        );
      } else {
        // Fallback ratio for uncalibrated display
        latestNormalizedFlex = packet.flex.map((raw) => ((raw - 1000) / 2200.0 * 100.0).clamp(0.0, 100.0)).toList();
      }

      notifyListeners();
    } catch (e) {
      // Decoder diagnostics tracks the count
    }
  }

  Future<bool> sendHapticPulse({String motor = 'both', int durationMs = 200}) async {
    try {
      final url = Uri.parse('http://$host:$port/api/control/haptic');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'motor': motor, 'duration_ms': durationMs}),
      ).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _channelSub?.cancel();
    _channelSub = null;
    await _channel?.sink.close();
    _channel = null;
    state = DeviceConnectionState.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _rateTimer?.cancel();
    _degradedTimer?.cancel();
    _channelSub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
