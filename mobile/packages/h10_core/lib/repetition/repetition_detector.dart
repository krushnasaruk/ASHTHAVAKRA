import 'dart:math' as math;
import '../models/repetition.dart';

enum RepetitionState { idle, rising, peakHold, falling, complete, rejected }

class RepetitionDetector {
  final double upperThreshold; // default 70%
  final double lowerThreshold; // default 30%
  final double minDurationS; // default 0.6s
  final double maxDurationS; // default 8.0s
  final double holdBandPct; // default ±5%
  final double minHoldDurationS; // default 0.5s
  final int debounceMs; // default 300ms

  RepetitionState _state = RepetitionState.idle;
  RepetitionState get state => _state;

  int _repCounter = 0;
  int get completedRepsCount => _repCounter;

  int _rejectedCounter = 0;
  int get rejectedRepsCount => _rejectedCounter;

  // Active repetition tracking
  int? _repStartMs;
  int? _lastCompleteEndMs;
  double _peak = 0.0;
  double _min = 100.0;
  final List<double> _signalSamples = [];
  final List<int> _sampleTimestamps = [];
  double _holdDurationS = 0.0;
  int? _holdStartMs;
  String? _lastRejectReason;
  String? get lastRejectReason => _lastRejectReason;

  RepetitionDetector({
    this.upperThreshold = 70.0,
    this.lowerThreshold = 30.0,
    this.minDurationS = 0.6,
    this.maxDurationS = 8.0,
    this.holdBandPct = 5.0,
    this.minHoldDurationS = 0.5,
    this.debounceMs = 300,
  });

  void reset() {
    _state = RepetitionState.idle;
    _repCounter = 0;
    _rejectedCounter = 0;
    _repStartMs = null;
    _lastCompleteEndMs = null;
    _peak = 0.0;
    _min = 100.0;
    _signalSamples.clear();
    _sampleTimestamps.clear();
    _holdDurationS = 0.0;
    _holdStartMs = null;
    _lastRejectReason = null;
  }

  /// Processes one time-stamped signal value.
  /// Returns a completed or rejected Repetition object on transition, or null.
  Repetition? processSample({
    required double signal,
    required int timestampMs,
    required String sessionId,
  }) {
    // Sensor fault check: signal out of valid normalized bounds
    if (signal < -5.0 || signal > 105.0) {
      if (_state != RepetitionState.idle) {
        return _rejectRepetition(
          sessionId: sessionId,
          timestampMs: timestampMs,
          reason: 'sensor_fault_out_of_range',
        );
      }
      return null;
    }

    switch (_state) {
      case RepetitionState.idle:
        // Debounce check against last completed rep
        if (_lastCompleteEndMs != null && (timestampMs - _lastCompleteEndMs!) < debounceMs) {
          return null;
        }

        // Start rising when signal crosses lowerThreshold from below
        if (signal > lowerThreshold) {
          _state = RepetitionState.rising;
          _repStartMs = timestampMs;
          _peak = signal;
          _min = signal;
          _signalSamples.clear();
          _sampleTimestamps.clear();
          _signalSamples.add(signal);
          _sampleTimestamps.add(timestampMs);
          _holdDurationS = 0.0;
          _holdStartMs = null;
          _lastRejectReason = null;
        }
        return null;

      case RepetitionState.rising:
        _signalSamples.add(signal);
        _sampleTimestamps.add(timestampMs);
        if (signal > _peak) _peak = signal;
        if (signal < _min) _min = signal;

        final durationS = (timestampMs - _repStartMs!) / 1000.0;
        if (durationS > maxDurationS) {
          return _rejectRepetition(
            sessionId: sessionId,
            timestampMs: timestampMs,
            reason: 'too_slow',
          );
        }

        // Reached upper threshold -> enter peak hold / falling
        if (signal >= upperThreshold) {
          _state = RepetitionState.peakHold;
          _holdStartMs = timestampMs;
        } else if (signal < lowerThreshold) {
          // Dropped back below lower threshold without reaching upper -> incomplete
          return _rejectRepetition(
            sessionId: sessionId,
            timestampMs: timestampMs,
            reason: 'incomplete',
          );
        }
        return null;

      case RepetitionState.peakHold:
        _signalSamples.add(signal);
        _sampleTimestamps.add(timestampMs);
        if (signal > _peak) {
          _peak = signal;
        }
        if (signal < _min) _min = signal;

        final durationS = (timestampMs - _repStartMs!) / 1000.0;
        if (durationS > maxDurationS) {
          return _rejectRepetition(
            sessionId: sessionId,
            timestampMs: timestampMs,
            reason: 'too_slow',
          );
        }

        // Hold check: within ±holdBandPct of peak
        final holdLower = math.max(0.0, _peak - holdBandPct);
        if (signal >= holdLower) {
          if (_holdStartMs != null) {
            _holdDurationS = (timestampMs - _holdStartMs!) / 1000.0;
          }
        } else {
          // Exited peak band -> now falling
          _state = RepetitionState.falling;
        }
        return null;

      case RepetitionState.falling:
        _signalSamples.add(signal);
        _sampleTimestamps.add(timestampMs);
        if (signal < _min) _min = signal;

        final durationS = (timestampMs - _repStartMs!) / 1000.0;
        if (durationS > maxDurationS) {
          return _rejectRepetition(
            sessionId: sessionId,
            timestampMs: timestampMs,
            reason: 'too_slow',
          );
        }

        // Complete when returning below lower threshold
        if (signal <= lowerThreshold) {
          if (durationS < minDurationS) {
            return _rejectRepetition(
              sessionId: sessionId,
              timestampMs: timestampMs,
              reason: 'too_fast',
            );
          }
          return _completeRepetition(sessionId: sessionId, timestampMs: timestampMs);
        }
        return null;

      case RepetitionState.complete:
      case RepetitionState.rejected:
        _state = RepetitionState.idle;
        return null;
    }
  }

  /// Discards active repetition on session stop / disconnect and logs as interrupted.
  Repetition? interrupt({required String sessionId, required int timestampMs}) {
    if (_state != RepetitionState.idle && _repStartMs != null) {
      final durationS = (timestampMs - _repStartMs!) / 1000.0;
      final mean = _signalSamples.isEmpty
          ? 0.0
          : _signalSamples.reduce((a, b) => a + b) / _signalSamples.length;

      final rep = Repetition(
        id: 'rep_${_repCounter + _rejectedCounter}_int',
        sessionId: sessionId,
        index: _repCounter,
        startMs: _repStartMs!,
        endMs: timestampMs,
        durationS: durationS,
        peak: _peak,
        mean: mean,
        min: _min,
        rom: math.max(0.0, _peak - _min),
        holdS: _holdDurationS >= minHoldDurationS ? _holdDurationS : 0.0,
        quality: RepetitionQuality.reduced,
        status: RepetitionStatus.interrupted,
        rejectReason: 'interrupted_session_disconnect',
      );
      reset();
      return rep;
    }
    reset();
    return null;
  }

  Repetition _completeRepetition({required String sessionId, required int timestampMs}) {
    final durationS = (timestampMs - _repStartMs!) / 1000.0;
    final mean = _signalSamples.reduce((a, b) => a + b) / _signalSamples.length;
    final rom = math.max(0.0, _peak - _min);
    final holdS = _holdDurationS >= minHoldDurationS ? _holdDurationS : 0.0;

    final rep = Repetition(
      id: 'rep_${_repCounter}_complete',
      sessionId: sessionId,
      index: _repCounter,
      startMs: _repStartMs!,
      endMs: timestampMs,
      durationS: durationS,
      peak: _peak,
      mean: mean,
      min: _min,
      rom: rom,
      holdS: holdS,
      quality: RepetitionQuality.good,
      status: RepetitionStatus.complete,
    );

    _repCounter++;
    _lastCompleteEndMs = timestampMs;
    _state = RepetitionState.idle;
    _signalSamples.clear();
    _sampleTimestamps.clear();
    return rep;
  }

  Repetition _rejectRepetition({
    required String sessionId,
    required int timestampMs,
    required String reason,
  }) {
    final startMs = _repStartMs ?? timestampMs;
    final durationS = (timestampMs - startMs) / 1000.0;
    final mean = _signalSamples.isEmpty
        ? 0.0
        : _signalSamples.reduce((a, b) => a + b) / _signalSamples.length;

    _lastRejectReason = reason;
    final rep = Repetition(
      id: 'rep_${_rejectedCounter}_reject',
      sessionId: sessionId,
      index: _repCounter,
      startMs: startMs,
      endMs: timestampMs,
      durationS: durationS,
      peak: _peak,
      mean: mean,
      min: _min,
      rom: math.max(0.0, _peak - _min),
      holdS: 0.0,
      quality: RepetitionQuality.invalid,
      status: RepetitionStatus.rejected,
      rejectReason: reason,
    );

    _rejectedCounter++;
    _lastCompleteEndMs = timestampMs;
    _state = RepetitionState.idle;
    _signalSamples.clear();
    _sampleTimestamps.clear();
    return rep;
  }
}
