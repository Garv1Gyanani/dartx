import 'dart:async';
import '../core/logger.dart';
import 'driver.dart';
import 'job.dart';
import 'metrics.dart';

/// Callback triggered when a job's lifecycle state changes.
typedef JobEventCallback = void Function(Job job);

/// Exception thrown when a job exceeds its [Job.timeout] duration.
class JobTimeoutException implements Exception {
  /// Creates a new [JobTimeoutException].
  JobTimeoutException(this.jobId, this.jobName, this.timeout);

  /// The unique ID of the job that timed out.
  final String jobId;

  /// The logical name of the job that timed out.
  final String jobName;

  /// The duration that was exceeded.
  final Duration timeout;

  @override
  String toString() =>
      'JobTimeoutException: Job [$jobName] (id: $jobId) exceeded timeout of ${timeout.inSeconds}s';
}

/// The background worker that processes jobs from one or more queues.
///
/// The [Worker] continuously polls the [QueueDriver] for available jobs,
/// executes them with timeout protection, handles retries with exponential
/// backoff, enforces rate limits, and tracks metrics.
///
/// ```dart
/// final worker = Worker(
///   driver: memoryDriver,
///   concurrency: 4,
///   maxJobsPerSecond: 10,
/// );
/// worker.onComplete = (job) => print('Done: ${job.name}');
/// worker.onFail = (job) => print('Failed permanently: ${job.name}');
/// worker.start();
/// ```
class Worker {
  /// Creates a new [Worker] instance.
  Worker({
    required this.driver,
    this.queues = const ['default'],
    this.pollInterval = const Duration(milliseconds: 500),
    this.concurrency = 1,
    this.maxJobsPerSecond = 0,
    QueueMetrics? metrics,
  }) : metrics = metrics ?? QueueMetrics();

  /// The queue storage backend.
  final QueueDriver driver;

  /// The queues this worker listens to. Defaults to `['default']`.
  final List<String> queues;

  /// How often the worker polls for new jobs.
  final Duration pollInterval;

  /// Maximum number of jobs to process concurrently.
  final int concurrency;

  /// Maximum number of jobs to start per second across all queues.
  ///
  /// Set to `0` (default) for unlimited throughput.
  final int maxJobsPerSecond;

  /// Metrics collector for this worker.
  final QueueMetrics metrics;

  /// Callback triggered when a job begins processing.
  JobEventCallback? onProcess;

  /// Callback triggered when a job completes successfully.
  JobEventCallback? onComplete;

  /// Callback triggered when a job is scheduled for retry.
  JobEventCallback? onRetry;

  /// Callback triggered when a job permanently fails.
  JobEventCallback? onFail;

  /// Callback triggered when a job times out.
  JobEventCallback? onTimeout;

  bool _running = false;
  int _activeJobs = 0;
  Timer? _pollTimer;
  Completer<void>? _stopCompleter;

  // Rate limiting state
  int _jobsStartedThisSecond = 0;
  Timer? _rateLimitResetTimer;

  /// Returns `true` if the worker is currently running.
  bool get isRunning => _running;

  /// Returns the number of jobs currently being processed.
  int get activeJobs => _activeJobs;

  /// Starts the worker loop. The returned future completes when [stop] is called.
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _stopCompleter = Completer<void>();
    metrics.start();

    Logger.staticInfo(
      '⚙️  Worker started — queues: ${queues.join(", ")} (concurrency: $concurrency${maxJobsPerSecond > 0 ? ', rate: ${maxJobsPerSecond}/s' : ''})',
    );

    // Start rate limit reset timer if rate limiting is enabled
    if (maxJobsPerSecond > 0) {
      _rateLimitResetTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _jobsStartedThisSecond = 0;
      });
    }

    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
    // Also do an immediate poll
    _poll();

    return _stopCompleter!.future;
  }

  /// Gracefully stops the worker. Waits for in-flight jobs to finish.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _pollTimer?.cancel();
    _rateLimitResetTimer?.cancel();

    Logger.staticInfo('⚙️  Worker stopping — waiting for $_activeJobs active job(s)...');

    // Wait for active jobs to drain (with a safety timeout)
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (_activeJobs > 0 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (_activeJobs > 0) {
      Logger.staticInfo('⚠️  Worker force-stopped with $_activeJobs job(s) still active');
    }

    Logger.staticInfo('⚙️  Worker stopped.');
    final completer = _stopCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// Internal: polls each queue for available work.
  void _poll() {
    if (!_running) return;

    for (final queue in queues) {
      if (_activeJobs >= concurrency) return;
      if (_isRateLimited) return;
      _tryProcess(queue);
    }
  }

  bool get _isRateLimited =>
      maxJobsPerSecond > 0 && _jobsStartedThisSecond >= maxJobsPerSecond;

  Future<void> _tryProcess(String queue) async {
    if (_activeJobs >= concurrency || !_running || _isRateLimited) return;

    final job = await driver.pop(queue);
    if (job == null) return;

    _activeJobs++;
    _jobsStartedThisSecond++;

    try {
      await _processJob(job);
    } finally {
      _activeJobs--;
    }

    // Immediately try to grab another job if there's capacity
    if (_running && _activeJobs < concurrency && !_isRateLimited) {
      _tryProcess(queue);
    }
  }

  Future<void> _processJob(Job job) async {
    job.attempts++;
    job.status = JobStatus.processing;
    final stopwatch = Stopwatch()..start();

    onProcess?.call(job);
    metrics.recordProcessing();
    Logger.staticInfo(
      '📋 Processing [${job.name}] (id: ${job.id}, attempt ${job.attempts}/${job.maxRetries})',
    );

    try {
      // Execute with timeout protection
      final timeoutVal = job.timeout;
      if (timeoutVal != null) {
        await job.handle().timeout(
          timeoutVal,
          onTimeout: () {
            throw JobTimeoutException(job.id, job.name, timeoutVal);
          },
        );
      } else {
        await job.handle();
      }

      stopwatch.stop();

      // Success!
      job.status = JobStatus.completed;
      job.finishedAt = DateTime.now();
      await driver.complete(job);
      onComplete?.call(job);
      metrics.recordSuccess(stopwatch.elapsed);
      Logger.staticInfo(
        '✅ [${job.name}] completed in ${stopwatch.elapsedMilliseconds}ms (id: ${job.id})',
      );
    } on JobTimeoutException catch (error, stackTrace) {
      stopwatch.stop();
      job.lastError = error;
      job.lastStackTrace = stackTrace;
      metrics.recordTimeout();
      onTimeout?.call(job);

      final timeoutVal = job.timeout;
      if (timeoutVal != null) {
        Logger.staticInfo(
          '⏱️  [${job.name}] TIMED OUT after ${timeoutVal.inSeconds}s (attempt ${job.attempts}/${job.maxRetries})',
        );
      }

      // Timeout is treated as a failure — eligible for retry
      try {
        await job.onFailure(error, stackTrace);
      } catch (_) {}
      await _handleFailure(job, error, stackTrace);
    } catch (error, stackTrace) {
      stopwatch.stop();
      job.lastError = error;
      job.lastStackTrace = stackTrace;

      Logger.staticInfo(
        '❌ [${job.name}] failed (attempt ${job.attempts}/${job.maxRetries}): $error',
      );

      try {
        await job.onFailure(error, stackTrace);
      } catch (_) {}
      await _handleFailure(job, error, stackTrace);
    }
  }

  Future<void> _handleFailure(Job job, Object error, StackTrace stackTrace) async {
    if (job.canRetry) {
      // Schedule for retry with exponential backoff
      job.status = JobStatus.pending;
      job.availableAt = DateTime.now().add(job.currentRetryDelay);
      await driver.release(job);
      onRetry?.call(job);
      metrics.recordRetry();
      Logger.staticInfo('🔄 [${job.name}] retry scheduled in ${job.currentRetryDelay.inSeconds}s');
    } else {
      // Permanent failure → dead letter queue
      job.status = JobStatus.failed;
      job.finishedAt = DateTime.now();
      await driver.fail(job);
      onFail?.call(job);
      metrics.recordPermanentFailure();

      try {
        await job.onPermanentFailure(error, stackTrace);
      } catch (_) {}

      Logger.staticInfo(
        '💀 [${job.name}] permanently failed after ${job.attempts} attempts → dead letter queue (id: ${job.id})',
      );
    }
  }
}
