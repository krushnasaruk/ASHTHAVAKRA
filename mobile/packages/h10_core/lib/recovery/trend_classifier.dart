enum TrendDirection { improving, declining, stable, variable, insufficientData }

class TrendResult {
  final TrendDirection direction;
  final String metricName;
  final double? baselineValue;
  final double? recentValue;
  final double? changePercent;
  final int sessionCountUsed;
  final String summary;

  const TrendResult({
    required this.direction,
    required this.metricName,
    this.baselineValue,
    this.recentValue,
    this.changePercent,
    required this.sessionCountUsed,
    required this.summary,
  });
}

class TrendClassifier {
  /// Classifies trend over the last N sessions (default 4).
  static TrendResult classify({
    required String metricName,
    required double baselineValue,
    required List<double> recentValues, // Chronological, last is newest
    int windowN = 4,
  }) {
    if (recentValues.length < windowN || baselineValue <= 0.0) {
      return TrendResult(
        direction: TrendDirection.insufficientData,
        metricName: metricName,
        sessionCountUsed: recentValues.length,
        summary: 'Insufficient data (needs at least $windowN sessions)',
      );
    }

    final window = recentValues.sublist(recentValues.length - windowN);
    final firstVal = window.first;
    final lastVal = window.last;
    final totalChange = lastVal - firstVal;
    final totalChangePct = (totalChange / baselineValue) * 100.0;

    // Check consecutive direction across the last 3 changes
    var allPositive = true;
    var allNegative = true;
    for (var i = 0; i < window.length - 1; i++) {
      final diff = window[i + 1] - window[i];
      if (diff <= 0) allPositive = false;
      if (diff >= 0) allNegative = false;
    }

    if (allPositive && totalChangePct >= 10.0) {
      return TrendResult(
        direction: TrendDirection.improving,
        metricName: metricName,
        baselineValue: baselineValue,
        recentValue: lastVal,
        changePercent: totalChangePct,
        sessionCountUsed: windowN,
        summary: 'Consistent improvement (+${totalChangePct.toStringAsFixed(1)}% over baseline)',
      );
    }

    if (allNegative && totalChangePct <= -10.0) {
      return TrendResult(
        direction: TrendDirection.declining,
        metricName: metricName,
        baselineValue: baselineValue,
        recentValue: lastVal,
        changePercent: totalChangePct,
        sessionCountUsed: windowN,
        summary: 'Consistent decline (${totalChangePct.toStringAsFixed(1)}% vs baseline)',
      );
    }

    // Stable: all within ±5% of baseline
    final allWithin5 = window.every((v) => ((v - baselineValue).abs() / baselineValue) <= 0.05);
    if (allWithin5) {
      return TrendResult(
        direction: TrendDirection.stable,
        metricName: metricName,
        baselineValue: baselineValue,
        recentValue: lastVal,
        changePercent: totalChangePct,
        sessionCountUsed: windowN,
        summary: 'Stable within ±5% of personal baseline',
      );
    }

    return TrendResult(
      direction: TrendDirection.variable,
      metricName: metricName,
      baselineValue: baselineValue,
      recentValue: lastVal,
      changePercent: totalChangePct,
      sessionCountUsed: windowN,
      summary: 'Variable movement quality across recent sessions',
    );
  }

  /// Checks for plateau across last 6 sessions.
  static Map<String, dynamic> checkPlateau({
    required double baselineRom,
    required double targetRom,
    required List<double> recentRoms, // last 6 sessions
  }) {
    if (recentRoms.length < 6 || baselineRom <= 0.0) {
      return {'is_plateau': false, 'reason': 'Requires at least 6 sessions'};
    }

    final window = recentRoms.sublist(recentRoms.length - 6);
    final minVal = window.reduce((a, b) => a < b ? a : b);
    final maxVal = window.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final rangePctOfBaseline = (range / baselineRom) * 100.0;
    final latestVal = window.last;

    // Range under 5% of baseline and plan target has not been reached
    if (rangePctOfBaseline < 5.0 && latestVal < targetRom) {
      return {
        'is_plateau': true,
        'range_pct': rangePctOfBaseline,
        'sessions_count': 6,
        'message': 'Plateau detected: ROM varied by only ${rangePctOfBaseline.toStringAsFixed(1)}% over the last 6 sessions without reaching target (${targetRom.toStringAsFixed(0)}%).',
      };
    }

    return {'is_plateau': false};
  }
}
