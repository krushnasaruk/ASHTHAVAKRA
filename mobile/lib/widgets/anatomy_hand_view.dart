import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'hand_view_platform_stub.dart'
    if (dart.library.html) 'hand_view_platform_web.dart';
import '../dev/mock_data.dart';

/// 3D Interactive Anatomical Hand Viewer for H10 Flutter App.
///
/// Features 27 anatomical hand bones (8 carpal, 5 metacarpal, 14 phalanx)
/// with medical-imaging styling, yellow bone shaft selection, small amber joint rings,
/// and responsive 4:5 portrait framing with safe-area insets.
///
/// Nonclinical engineering demonstration prototype.
class AnatomyHandView extends StatefulWidget {
  final List<double> normalizedFlex; // [thumb, index, middle, ring, pinky] in 0-100%
  final List<int>? imu;              // ax, ay, az, gx, gy, gz or quaternion
  final bool isConnected;
  final VoidCallback? onClose;
  final bool isFullScreen;

  const AnatomyHandView({
    super.key,
    required this.normalizedFlex,
    this.imu,
    this.isConnected = true,
    this.onClose,
    this.isFullScreen = false,
  });

  @override
  State<AnatomyHandView> createState() => _AnatomyHandViewState();
}

class _AnatomyHandViewState extends State<AnatomyHandView> {
  WebViewController? _controller;
  bool _isPageReady = false;
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
    if (kIsWeb) {
      _isPageReady = true;
      return;
    }

    if (WebViewPlatform.instance == null) {
      _controller = null;
      return;
    }

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF000000))
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

      _loadLocalAnatomyAsset();
    } catch (_) {
      _controller = null;
    }
  }

  Future<void> _loadLocalAnatomyAsset() async {
    if (_controller == null) return;
    try {
      await _controller!.loadFlutterAsset('assets/hand/anatomy.html');
    } catch (_) {
      try {
        await _controller!.loadRequest(Uri.parse('assets/assets/hand/anatomy.html'));
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
      _mockPhase += 0.08;
      final wave = (math.sin(_mockPhase) * 0.5 + 0.5).clamp(0.0, 1.0);
      thumbCurl = (wave * 0.85).clamp(0.0, 1.0);
      indexCurl = wave;
      middleCurl = wave;
      ringCurl = (wave * 0.90).clamp(0.0, 1.0);
      pinkyCurl = (wave * 0.75).clamp(0.0, 1.0);
    } else {
      // Neutral open pose when disconnected
      thumbCurl = 0.0;
      indexCurl = 0.0;
      middleCurl = 0.0;
      ringCurl = 0.0;
      pinkyCurl = 0.0;
    }

    // IMU orientation quaternion
    double qw = 1.0, qx = 0.0, qy = 0.0, qz = 0.0;
    if (widget.imu != null && widget.imu!.length >= 4) {
      if (widget.imu!.length == 4) {
        qw = widget.imu![0] / 1000.0;
        qx = widget.imu![1] / 1000.0;
        qy = widget.imu![2] / 1000.0;
        qz = widget.imu![3] / 1000.0;
      } else if (widget.imu!.length >= 6) {
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
      'action': 'setFrame',
      'data': {
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
      },
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

    if (kIsWeb) {
      postPlatformMessage(framePayload, 'hand-anatomy-3d');
      return;
    }

    if (_controller == null) return;
    try {
      _controller!.runJavaScript('if(window.setFrame){window.setFrame($framePayload);}');
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant AnatomyHandView oldWidget) {
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
    // Respect safe-area insets at top and bottom
    return SafeArea(
      top: widget.isFullScreen,
      bottom: widget.isFullScreen,
      child: Center(
        child: Padding(
          // At least 16 px padding on all sides per spec
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 440,
            ),
            // 4:5 Portrait Frame centered horizontally per Section 3 spec
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222628), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.70),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      // WebView / WebGL Canvas hosting anatomy.html
                      kIsWeb
                          ? buildPlatformHandView(
                              viewType: 'hand-anatomy-3d',
                              assetUrl: 'assets/assets/hand/anatomy.html',
                            )
                          : (_controller != null
                              ? WebViewWidget(controller: _controller!)
                              : Container(
                                  color: const Color(0xFF000000),
                                  child: const Center(
                                    child: Text(
                                      '3D ANATOMICAL SKELETON (WEBGL)',
                                      style: TextStyle(
                                        color: Color(0xFFFFD54A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                )),

                      // Optional Close Button for Fullscreen modal
                      if (widget.onClose != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161A1C),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF333A3E)),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFFC9D0D4),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
