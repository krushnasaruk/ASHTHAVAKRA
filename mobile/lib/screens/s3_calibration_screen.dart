import 'dart:async';
import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';

class CalibrationScreen extends StatefulWidget {
  final DeviceService deviceService;
  final StorageService storageService;

  const CalibrationScreen({
    super.key,
    required this.deviceService,
    required this.storageService,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  int _stage = 1; // 1: open hand, 2: fist, 3: review
  bool _isCapturing = false;
  int _countdown = 3;
  double _captureProgress = 0.0;

  final List<List<int>> _openSamples = [];
  final List<List<int>> _closedSamples = [];

  CalibrationRecord? _computedRecord;
  String? _statusError;

  final CalibrationEngine _engine = const CalibrationEngine();

  void _startCapture(int stage) {
    setState(() {
      _stage = stage;
      _isCapturing = true;
      _countdown = 3;
      _captureProgress = 0.0;
      _statusError = null;
    });

    if (stage == 1) _openSamples.clear();
    if (stage == 2) _closedSamples.clear();

    // 3-second countdown then 2-second capture
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _recordCaptureSamples(stage);
      }
    });
  }

  void _recordCaptureSamples(int stage) {
    // 2-second window at 50 Hz = 100 samples
    var collected = 0;
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final latest = widget.deviceService.latestPacket;
      if (latest != null) {
        if (stage == 1) _openSamples.add(List<int>.from(latest.flex));
        if (stage == 2) _closedSamples.add(List<int>.from(latest.flex));
        collected++;
        setState(() => _captureProgress = collected / 100.0);
      }

      if (collected >= 100) {
        timer.cancel();
        _finishStage(stage);
      }
    });
  }

  void _finishStage(int stage) {
    setState(() => _isCapturing = false);

    if (stage == 1) {
      final eval = _engine.evaluateCaptureWindow(_openSamples);
      if (!eval['is_stable']) {
        setState(() => _statusError = eval['reason']);
        return;
      }
      // Advance to stage 2
      setState(() => _stage = 2);
    } else if (stage == 2) {
      final eval = _engine.evaluateCaptureWindow(_closedSamples);
      if (!eval['is_stable']) {
        setState(() => _statusError = eval['reason']);
        return;
      }

      // Compute final calibration
      final openEval = _engine.evaluateCaptureWindow(_openSamples);
      final closedEval = _engine.evaluateCaptureWindow(_closedSamples);

      final record = _engine.buildRecord(
        id: 'cal_${DateTime.now().millisecondsSinceEpoch}',
        openMedians: (openEval['medians'] as List).cast<double>(),
        openSds: (openEval['sds'] as List).cast<double>(),
        closedMedians: (closedEval['medians'] as List).cast<double>(),
        closedSds: (closedEval['sds'] as List).cast<double>(),
      );

      setState(() {
        _computedRecord = record;
        _stage = 3;
      });
    }
  }

  Future<void> _saveCalibration() async {
    if (_computedRecord != null && _computedRecord!.isValid) {
      await widget.storageService.saveCalibration(_computedRecord!);
      widget.deviceService.activeCalibration = _computedRecord;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calibration saved successfully!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration Wizard'),
        backgroundColor: const Color(H10Tokens.colorBackground),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(H10Tokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage Indicator
            Row(
              children: [
                _stageStep(1, 'Open Hand', _stage >= 1),
                const Expanded(child: Divider(color: Color(H10Tokens.colorBorder), thickness: 2)),
                _stageStep(2, 'Full Fist', _stage >= 2),
                const Expanded(child: Divider(color: Color(H10Tokens.colorBorder), thickness: 2)),
                _stageStep(3, 'Review & Save', _stage == 3),
              ],
            ),
            const SizedBox(height: H10Tokens.space24),

            if (_stage == 1) ...[
              const Text('STAGE 1: OPEN HAND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
              const SizedBox(height: 8),
              const Text('Hold your hand fully open and flat on a resting surface. Remain completely relaxed and steady.', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
              _captureBox(1, 'Capture Open Hand'),
            ] else if (_stage == 2) ...[
              const Text('STAGE 2: FULL FIST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
              const SizedBox(height: 8),
              const Text('Clench your hand into a firm, comfortable fist. Hold steady without over-straining.', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
              _captureBox(2, 'Capture Closed Fist'),
            ] else if (_stage == 3 && _computedRecord != null) ...[
              const Text('CALIBRATION RESULTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
              const SizedBox(height: 12),
              _resultsTable(_computedRecord!),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _startCapture(1),
                      child: const Text('Recalibrate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _computedRecord!.isValid ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorSecondaryText),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _computedRecord!.isValid ? _saveCalibration : null,
                      child: const Text('Save Calibration'),
                    ),
                  ),
                ],
              ),
            ],

            if (_statusError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Color(H10Tokens.colorError)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_statusError!, style: const TextStyle(color: Color(H10Tokens.colorError)))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stageStep(int step, String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? const Color(H10Tokens.colorPrimary) : const Color(0xFFE0E5E2),
          child: Text('$step', style: TextStyle(fontSize: 12, color: isActive ? Colors.white : const Color(H10Tokens.colorSecondaryText))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _captureBox(int stage, String buttonText) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(H10Tokens.colorCard),
        borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
        border: Border.all(color: const Color(H10Tokens.colorBorder)),
      ),
      child: Column(
        children: [
          if (_isCapturing) ...[
            Text('$_countdown', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(H10Tokens.colorPrimary))),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _captureProgress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            const Text('Keep hand steady...'),
          ] else ...[
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(H10Tokens.colorPrimary),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _startCapture(stage),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultsTable(CalibrationRecord record) {
    return Table(
      border: TableBorder.all(color: const Color(H10Tokens.colorBorder), borderRadius: BorderRadius.circular(8)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(3),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFEFEFEA)),
          children: const [
            Padding(padding: EdgeInsets.all(8), child: Text('Finger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.all(8), child: Text('Open', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.all(8), child: Text('Fist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.all(8), child: Text('Span', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        ...record.fingers.map((f) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(f.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            Padding(padding: const EdgeInsets.all(8), child: Text(f.openValue.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8), child: Text(f.closedValue.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.all(8), child: Text(f.span.toStringAsFixed(0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                f.isValid ? 'VALID' : f.rejectReason ?? 'INVALID',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: f.isValid ? const Color(H10Tokens.colorSuccess) : const Color(H10Tokens.colorError),
                ),
              ),
            ),
          ],
        )),
      ],
    );
  }
}

