import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../dev/mock_data.dart';

enum HandRenderMode { skin, mesh, xray }

/// Realistic 3D Human Hand View powered by local Three.js & GLTF runtime
/// inside an isolated, hardware-accelerated WebView.
class HandView extends StatefulWidget {
  final List<double> normalizedFlex; // [thumb, index, middle, ring, pinky] in 0-100%
  final List<int>? imu;              // ax, ay, az, gx, gy, gz or quaternion
  final bool isConnected;
  final double height;
  final bool showRenderModeSelector;

  const HandView({
    super.key,
    required this.normalizedFlex,
    this.imu,
    this.isConnected = true,
    this.height = 240,
    this.showRenderModeSelector = true,
  });

  @override
  State<HandView> createState() => _HandViewState();
}

class _HandViewState extends State<HandView> {
  WebViewController? _controller;
  bool _isPageReady = false;
  HandRenderMode _currentMode = HandRenderMode.skin;

  Timer? _frameTimer;
  double _mockPhase = 0.0;
  DateTime _lastFrameTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    _startFrameLoop();
  }

  void _initWebViewController() {
    if (WebViewPlatform.instance == null) {
      _controller = null;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isPageReady = true);
              _pushCurrentFrame();
            }
          },
        ),
      );

    _loadLocalHandAsset();
  }

  Future<void> _loadLocalHandAsset() async {
    if (_controller == null) return;
    try {
      await _controller!.loadFlutterAsset('assets/hand/hand_view.html');
    } catch (_) {
      // Fallback for Web/desktop test environments
      try {
        await _controller!.loadRequest(Uri.parse('assets/assets/hand/hand_view.html'));
      } catch (_) {}
    }
  }

  void _startFrameLoop() {
    // Throttle to 25 Hz (40 ms interval per spec)
    _frameTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_isPageReady || !mounted) return;
      _pushCurrentFrame();
    });
  }

  void _pushCurrentFrame() {
    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < 35) return;
    _lastFrameTime = now;

    double thumbCurl, indexCurl, middleCurl, ringCurl, pinkyCurl;

    if (widget.isConnected) {
      // Measured channels (calibrated 0.0 - 1.0)
      thumbCurl = ((widget.normalizedFlex.isNotEmpty ? widget.normalizedFlex[0] : 0.0) / 100.0).clamp(0.0, 1.0);
      indexCurl = ((widget.normalizedFlex.length > 1 ? widget.normalizedFlex[1] : 0.0) / 100.0).clamp(0.0, 1.0);
      middleCurl = ((widget.normalizedFlex.length > 2 ? widget.normalizedFlex[2] : 0.0) / 100.0).clamp(0.0, 1.0);

      // Estimated channels per spec:
      // ring = 0.9 * middle, pinky = 0.75 * middle
      ringCurl = (middleCurl * 0.90).clamp(0.0, 1.0);
      pinkyCurl = (middleCurl * 0.75).clamp(0.0, 1.0);
    } else if (kUseMockData) {
      // Smooth sine wave curl for offline dev testing
      _mockPhase += 0.08;
      final wave = (math.sin(_mockPhase) * 0.5 + 0.5).clamp(0.0, 1.0);
      thumbCurl = (wave * 0.85).clamp(0.0, 1.0);
      indexCurl = wave;
      middleCurl = wave;
      ringCurl = (wave * 0.90).clamp(0.0, 1.0);
      pinkyCurl = (wave * 0.75).clamp(0.0, 1.0);
    } else {
      // Disconnected with mock OFF: neutral open hand pose (0.0 curl)
      thumbCurl = 0.0;
      indexCurl = 0.0;
      middleCurl = 0.0;
      ringCurl = 0.0;
      pinkyCurl = 0.0;
    }

    // IMU orientation quaternion calculation
    double qw = 1.0, qx = 0.0, qy = 0.0, qz = 0.0;
    if (widget.imu != null && widget.imu!.length >= 4) {
      // If direct quaternion format is sent (qw, qx, qy, qz)
      if (widget.imu!.length == 4) {
        qw = widget.imu![0] / 1000.0;
        qx = widget.imu![1] / 1000.0;
        qy = widget.imu![2] / 1000.0;
        qz = widget.imu![3] / 1000.0;
      } else if (widget.imu!.length >= 6) {
        // Compute orientation from accelerometer vector (ax, ay, az in mg)
        final ax = widget.imu![0].toDouble();
        final ay = widget.imu![1].toDouble();
        final az = widget.imu![2].toDouble();
        final norm = math.sqrt(ax * ax + ay * ay + az * az);
        if (norm > 100) {
          final pitch = math.atan2(ay, math.sqrt(ax * ax + az * az)) * 0.5;
          final roll = math.atan2(-ax, az) * 0.5;
          qx = math.sin(pitch);
          qy = math.sin(roll);
          qz = 0.0;
          qw = math.cos(pitch) * math.cos(roll);
        }
      }
    }

    final framePayload = jsonEncode({
      'curl': {
        'thumb': thumbCurl,
        'index': indexCurl,
        'middle': middleCurl,
        'ring': ringCurl,
        'pinky': pinkyCurl,
      },
      'imu': {
        'qw': qw,
        'qx': qx,
        'qy': qy,
        'qz': qz,
      },
    });

    if (_controller == null) return;
    try {
      _controller!.runJavaScript('if(window.setFrame){window.setFrame($framePayload);}');
    } catch (_) {}
  }

  void _switchRenderMode(HandRenderMode mode) {
    setState(() => _currentMode = mode);
    if (_controller == null) return;
    final modeStr = mode.name;
    try {
      _controller!.runJavaScript('if(window.setRenderMode){window.setRenderMode("$modeStr");}');
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant HandView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isPageReady) {
      _pushCurrentFrame();
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF262016), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 3D Three.js Human Hand WebView or Test Fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: _controller != null
                ? WebViewWidget(controller: _controller!)
                : Container(
                    color: const Color(0xFF0A0A0A),
                    child: const Center(
                      child: Text(
                        '3D HUMAN HAND (WEBGL)',
                        style: TextStyle(
                          color: Color(0xFFFFD38A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),

          // Top Header: Segmented Control (SKIN / MESH / XRAY) & Channel Mode Tag
          if (widget.showRenderModeSelector)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Segmented Render Mode Switcher
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14120E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E261A), width: 0.9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeButton(HandRenderMode.skin, 'SKIN'),
                        _buildModeButton(HandRenderMode.mesh, 'MESH'),
                        _buildModeButton(HandRenderMode.xray, 'XRAY'),
                      ],
                    ),
                  ),

                  // Connection & Estimation Tag
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF5A623).withOpacity(0.4)),
                        ),
                        child: Text(
                          widget.isConnected ? '3-CH (EST. 4&5)' : 'NO DEVICE',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: widget.isConnected ? const Color(0xFFFFD38A) : const Color(0xFF8E958E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton(HandRenderMode mode, String label) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => _switchRenderMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5A623) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF5A623).withOpacity(0.4),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: isSelected ? const Color(0xFF0A0A0A) : const Color(0xFF8E958E),
          ),
        ),
      ),
    );
  }
}
