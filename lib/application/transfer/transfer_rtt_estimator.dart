class TransferRttEstimator {
  TransferRttEstimator({
    this.initialTimeout = const Duration(milliseconds: 450),
    this.minimumTimeout = const Duration(milliseconds: 250),
    this.maximumTimeout = const Duration(seconds: 3),
  }) : _currentTimeout = initialTimeout;

  final Duration initialTimeout;
  final Duration minimumTimeout;
  final Duration maximumTimeout;

  Duration _currentTimeout;
  double? _srttMs;
  double? _rttVarMs;

  Duration get currentTimeout => _currentTimeout;

  double? get smoothedRttMs => _srttMs;

  void recordSample(Duration sample) {
    final sampleMs = sample.inMilliseconds.toDouble();
    if (_srttMs == null || _rttVarMs == null) {
      _srttMs = sampleMs;
      _rttVarMs = sampleMs / 2;
    } else {
      final srtt = _srttMs!;
      final rttVar = _rttVarMs!;
      final nextVar = (1 - 0.25) * rttVar + 0.25 * (srtt - sampleMs).abs();
      final nextSrtt = (1 - 0.125) * srtt + 0.125 * sampleMs;
      _srttMs = nextSrtt;
      _rttVarMs = nextVar;
    }

    final timeoutMs = (_srttMs! + 4 * _rttVarMs!).round();
    _currentTimeout = _clamp(Duration(milliseconds: timeoutMs));
  }

  void noteTimeoutBackoff() {
    _currentTimeout = _clamp(_currentTimeout * 2);
  }

  Duration _clamp(Duration value) {
    if (value < minimumTimeout) {
      return minimumTimeout;
    }
    if (value > maximumTimeout) {
      return maximumTimeout;
    }
    return value;
  }
}
