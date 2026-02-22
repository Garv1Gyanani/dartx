import 'dart:async';
import 'job.dart';
import 'driver.dart';
import '../core/logger.dart';

/// Callback triggered when a job's lifecycle state changes.
typedef JobEventCallback = void Function(Job job);

/// The background worker that processes jobs from one or more queues.
///
/// The [Worker] continuously polls the [QueueDriver] for available jobs,
/// executes them, handles retries with exponential backoff, and emits
/// lifecycle events.
///
/// ```dart
/// final worker = Worker(driver: memoryDriver);
/// worker.onComplete = (job) => print('Done: ${job.name}');
/// worker.onFail = (job) => print('Failed permanently: ${job.name}');
/// worker.start();
/// ```
class Worker {
  final QueueDriver driver;

  /// The queues this worker listens to. Defaults to `['default']`.
  final List<String> queues;

  /// How often the worker polls for new jobs (in milliseconds).
  final Duration pollInterval;

  /// Maximum number of jobs to process concurrently.
  final int concurrency;

  /// Lifecycle callbacks
  JobEventCallback? onProcess;
  JobEventCallback? onComplete;
  JobEventCallback? onRetry;
  JobEventCallback? onFail;

  bool _running = false;
  int _activeJobs = 0;
  Timer? _pollTimer;
  final Completer<void> _stopCompleter = Completer<void>();

  /// Returns `true` if the worker is currently running.
  bool get isRunning => _running;

  /// Returns the number of jobs currently being processed.
  int get activeJobs => _activeJobs;

  Worker({
    required this.driver,
    this.queues = const ['default'],
    this.pollInterval = const Duration(milliseconds: 500),
    this.concurrency = 1,
  });

  /// Starts the worker loop. The returned future completes when [stop] is called.
  Future<void> start() async {
    if (_running) return;
    _running = true;

    Logger.staticInfo('⚙️  Worker started — listening on queues: ${queues.join(", ")} (concurrency: $concurrency)');

    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
    // Also do an immediate poll
    _poll();

    return _stopCompleter.future;
  }

  /// Gracefully stops the worker. Waits for in-flight jobs to finish.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _pollTimer?.cancel();

    Logger.staticInfo('⚙️  Worker stopping — waiting for $activeJobs active job(s)...');

    // Wait for active jobs to drain
    while (_activeJobs > 0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    Logger.staticInfo('⚙️  Worker stopped.');
    if (!_stopCompleter.isCompleted) {
      _stopCompleter.complete();
    }
  }

  /// Internal: polls each queue for available work.
  void _poll() {
    if (!_running) return;

    for (final queue in queues) {
      if (_activeJobs >= concurrency) return;
      _tryProcess(queue);
    }
  }

  Future<void> _tryProcess(String queue) async {
    if (_activeJobs >= concurrency || !_running) return;

    final job = await driver.pop(queue);
    if (job == null) return;

    _activeJobs++;

    try {
      await _processJob(job);
    } finally {
      _activeJobs--;
    }

    // Immediately try to grab another job if there's capacity
    if (_running && _activeJobs < concurrency) {
      _tryProcess(queue);
    }
  }

  Future<void> _processJob(Job job) async {
    job.attempts++;
    job.status = JobStatus.processing;

    onProcess?.call(job);
    Logger.staticInfo('📋 Processing job [${job.name}] (id: ${job.id}, attempt ${job.attempts}/${job.maxRetries})');

    try {
      await job.handle();

      // Success!
      job.status = JobStatus.completed;
      await driver.complete(job);
      onComplete?.call(job);
      Logger.staticInfo('✅ Job [${job.name}] completed (id: ${job.id})');
    } catch (error, stackTrace) {
      job.lastError = error;
      job.lastStackTrace = stackTrace;

      Logger.staticInfo('❌ Job [${job.name}] failed (attempt ${job.attempts}/${job.maxRetries}): $error');

      // Notify the job about the failure
      try {
        await job.onFailure(error, stackTrace);
      } catch (_) {}

      if (job.canRetry) {
        // Schedule for retry with exponential backoff
        job.status = JobStatus.pending;
        job.availableAt = DateTime.now().add(job.currentRetryDelay);
        await driver.release(job);
        onRetry?.call(job);
        Logger.staticInfo('🔄 Job [${job.name}] scheduled for retry in ${job.currentRetryDelay.inSeconds}s');
      } else {
        // Permanent failure
        job.status = JobStatus.failed;
        await driver.fail(job);
        onFail?.call(job);

        try {
          await job.onPermanentFailure(error, stackTrace);
        } catch (_) {}

        Logger.staticInfo('💀 Job [${job.name}] permanently failed after ${job.attempts} attempts (id: ${job.id})');
      }
    }
  }
}
