/// Exponential Moving Average filter.
class EmaFilter {
  final double alpha;
  double? _lastValue;

  EmaFilter({this.alpha = 0.25}) {
    if (alpha <= 0.0 || alpha > 1.0) {
      throw ArgumentError('Alpha must be in (0, 1]');
    }
  }

  double process(double input) {
    if (_lastValue == null) {
      _lastValue = input;
      return input;
    }
    _lastValue = (alpha * input) + ((1.0 - alpha) * _lastValue!);
    return _lastValue!;
  }

  void reset() {
    _lastValue = null;
  }
}

