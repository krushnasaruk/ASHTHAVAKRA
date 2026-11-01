/// Sliding window median filter for spike suppression.
class MedianFilter {
  final int windowSize;
  final List<double> _buffer = [];

  MedianFilter({this.windowSize = 5}) {
    if (windowSize < 1 || windowSize % 2 == 0) {
      throw ArgumentError('Window size must be an odd positive integer');
    }
  }

  double process(double input) {
    _buffer.add(input);
    if (_buffer.length > windowSize) {
      _buffer.removeAt(0);
    }
    final sorted = List<double>.from(_buffer)..sort();
    return sorted[sorted.length ~/ 2];
  }

  void reset() {
    _buffer.clear();
  }
}

