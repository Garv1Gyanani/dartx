/// Tracks real-time metrics for the queue system.
///
/// Provides counters and timing data for monitoring queue health,
/// including throughput, failure rates, and processing durations.
///
/// ```dart
/// final metrics = QueueMetrics();
/// worker.onComplete = (job) => metrics.recordSuccess(job);
/// worker.onFail = (job) => metrics.recordPermanentFailure(job);
///
/// // Later, inspect:
/// print(metrics.snapshot);
/// ```
class QueueMetrics {
  int _dispatched = 0;
  int _processed = 0;
  int _succeeded = 0;
  int _failed = 0;
  int _retried = 0;
  int _timedOut = 0;
  final List<int> _durations = []; // milliseconds
  DateTime? _startedAt;

  /// Call when the metrics system starts tracking (e.g., when the worker starts).
  void start() {
    _startedAt = DateTime.now();
  }

  /// Records a job being dispatched.
  void recordDispatch() => _dispatched++;

  /// Records a job being picked up for processing.
  void recordProcessing() => _processed++;

  /// Records a successful job completion with its [duration].
  void recordSuccess(Duration duration) {
    _succeeded++;
    _durations.add(duration.inMilliseconds);
  }

  /// Records a job failure that will be retried.
  void recordRetry() => _retried++;

  /// Records a permanent failure (dead letter).
  void recordPermanentFailure() => _failed++;

  /// Records a job that was killed due to timeout.
  void recordTimeout() => _timedOut++;

  /// Average processing time in milliseconds, or 0 if no data.
  double get averageProcessingTimeMs {
    if (_durations.isEmpty) return 0;
    return _durations.reduce((a, b) => a + b) / _durations.length;
  }

  /// 95th percentile processing time in milliseconds.
  double get p95ProcessingTimeMs {
    if (_durations.isEmpty) return 0;
    final sorted = List<int>.from(_durations)..sort();
    final idx = (sorted.length * 0.95).ceil() - 1;
    return sorted[idx.clamp(0, sorted.length - 1)].toDouble();
  }

  /// Throughput: jobs completed per second since start.
  double get throughput {
    if (_startedAt == null || _succeeded == 0) return 0;
    final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
    return elapsed > 0 ? _succeeded / elapsed : 0;
  }

  /// Failure rate as a percentage (0–100).
  double get failureRate {
    final total = _succeeded + _failed;
    return total > 0 ? (_failed / total) * 100 : 0;
  }

  /// Resets all counters. Useful for testing.
  void reset() {
    _dispatched = 0;
    _processed = 0;
    _succeeded = 0;
    _failed = 0;
    _retried = 0;
    _timedOut = 0;
    _durations.clear();
    _startedAt = null;
  }

  /// Returns a point-in-time snapshot of all metrics.
  Map<String, dynamic> get snapshot => {
        'dispatched': _dispatched,
        'processed': _processed,
        'succeeded': _succeeded,
        'failed': _failed,
        'retried': _retried,
        'timedOut': _timedOut,
        'averageProcessingTimeMs': averageProcessingTimeMs.round(),
        'p95ProcessingTimeMs': p95ProcessingTimeMs.round(),
        'throughputPerSecond': double.parse(throughput.toStringAsFixed(2)),
        'failureRatePercent': double.parse(failureRate.toStringAsFixed(2)),
        'uptime': _startedAt != null
            ? DateTime.now().difference(_startedAt!).toString()
            : null,
      };
}
