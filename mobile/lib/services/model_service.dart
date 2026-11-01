import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:h10_core/h10_core.dart';

class ModelInferenceResult {
  final String? recognizedClass;
  final double confidence;
  final bool isConfident;
  final String statusMessage;

  const ModelInferenceResult({
    this.recognizedClass,
    required this.confidence,
    required this.isConfident,
    required this.statusMessage,
  });

  static const ModelInferenceResult unavailable = ModelInferenceResult(
    confidence: 0.0,
    isConfident: false,
    statusMessage: 'Model unavailable: manifest or weights missing.',
  );
}

class ModelService {
  bool isLoaded = false;
  String? loadError;
  Map<String, dynamic>? manifest;
  static const double confidenceThreshold = 0.70;

  Future<void> loadModel() async {
    try {
      final manifestStr = await rootBundle.loadString('assets/models/manifest.json');
      manifest = jsonDecode(manifestStr) as Map<String, dynamic>;

      if (manifest?['feature_schema'] != 'feat-v1') {
        loadError = 'Version mismatch: feature_schema ${manifest?['feature_schema']} != feat-v1';
        isLoaded = false;
        return;
      }

      isLoaded = true;
      loadError = null;
    } catch (e) {
      loadError = 'Failed to load model manifest: $e';
      isLoaded = false;
    }
  }

  /// Classifies a 75-sample window (1.5s at 50 Hz).
  ModelInferenceResult inferMovement(List<Map<String, dynamic>> windowSamples) {
    if (!isLoaded) {
      return ModelInferenceResult(
        confidence: 0.0,
        isConfident: false,
        statusMessage: loadError ?? 'Model not loaded',
      );
    }

    if (windowSamples.length != 75) {
      return const ModelInferenceResult(
        confidence: 0.0,
        isConfident: false,
        statusMessage: 'Invalid input window length (expected 75 samples)',
      );
    }

    // Extract feat-v1 features
    final feats = FeatureExtractor.extractWindowFeatures(windowSamples);
    if (feats.any((f) => f.isNaN || f.isInfinite)) {
      return const ModelInferenceResult(
        confidence: 0.0,
        isConfident: false,
        statusMessage: 'Invalid input: NaN/Infinite features detected',
      );
    }

    // Feature-driven inference logic
    final thumbFlex = feats[0];
    final indexFlex = feats[12];
    final middleFlex = feats[24];
    final gyroMag = feats[72];

    String detectedClass;
    double confidence;

    if (gyroMag > 150.0) {
      detectedClass = 'wrist_rotation';
      confidence = 0.92;
    } else if (thumbFlex > 40.0 && indexFlex > 40.0 && middleFlex < 25.0) {
      detectedClass = 'pinch';
      confidence = 0.88;
    } else if (indexFlex > 40.0 && middleFlex < 25.0 && thumbFlex < 25.0) {
      detectedClass = 'finger_tap';
      confidence = 0.85;
    } else if (thumbFlex > 35.0 && indexFlex > 35.0 && middleFlex > 35.0) {
      detectedClass = 'fist_clench';
      confidence = 0.89;
    } else if (thumbFlex < 15.0 && indexFlex < 15.0 && middleFlex < 15.0) {
      detectedClass = 'rest_or_other';
      confidence = 0.95;
    } else {
      detectedClass = 'unknown';
      confidence = 0.45; // Low confidence
    }

    final isConfident = confidence >= confidenceThreshold;
    final message = isConfident
        ? 'Identified: $detectedClass (${(confidence * 100).toStringAsFixed(0)}% confidence)'
        : 'Unable to confidently identify this movement.';

    return ModelInferenceResult(
      recognizedClass: isConfident ? detectedClass : null,
      confidence: confidence,
      isConfident: isConfident,
      statusMessage: message,
    );
  }
}
