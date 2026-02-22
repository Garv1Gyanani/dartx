import 'dart:async';
import 'job.dart';
import 'driver.dart';
import 'worker.dart';
import '../di/container.dart';
import '../core/logger.dart';

/// High-level facade for the queue system.
///
/// [Queue] provides a clean API for dispatching jobs and managing workers.
/// Register it as a singleton in the DI container for framework-wide access.
///
/// ```dart
/// final queue = Queue(driver: MemoryQueueDriver());
/// queue.dispatch(SendEmailJob('[email protected]', 'Hello!'));
/// queue.work(); // starts background processing
/// ```
class Queue {
  final QueueDriver driver;
  Worker? _worker;

  /// Returns `true` if a worker is currently running.
  bool get isProcessing => _worker?.isRunning ?? false;

  Queue({required this.driver});

  // ---------------------------------------------------------------------------
  // Dispatch API
  // ---------------------------------------------------------------------------

  /// Dispatches a [job] to its designated queue for background processing.
  Future<String> dispatch(Job job) async {
    await driver.push(job, job.queue);
    Logger.staticInfo('📤 Dispatched [${job.name}] to queue "${job.queue}" (id: ${job.id})');
    return job.id;
  }

  /// Dispatches a [job] with a delay before it becomes available.
  Future<String> dispatchAfter(Duration delay, Job job) async {
    job.availableAt = DateTime.now().add(delay);
    await driver.push(job, job.queue);
    Logger.staticInfo('📤 Dispatched [${job.name}] to queue "${job.queue}" (available in ${delay.inSeconds}s)');
    return job.id;
  }

  /// Dispatches a [job] and processes it synchronously (blocks until done).
  ///
  /// Useful for testing or when you need the result immediately.
  Future<void> dispatchSync(Job job) async {
    Logger.staticInfo('⚡ Processing [${job.name}] synchronously');
    job.attempts++;
    job.status = JobStatus.processing;
    try {
      await job.handle();
      job.status = JobStatus.completed;
    } catch (error, stackTrace) {
      job.lastError = error;
      job.status = JobStatus.failed;
      await job.onFailure(error, stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Worker Management
  // ---------------------------------------------------------------------------

  /// Starts a background worker to process jobs.
  ///
  /// [queues] defines which queues to listen to.
  /// [concurrency] controls how many jobs run in parallel.
  /// [pollInterval] controls how often the worker polls for new jobs.
  Future<void> work({
    List<String> queues = const ['default'],
    int concurrency = 1,
    Duration pollInterval = const Duration(milliseconds: 500),
    JobEventCallback? onProcess,
    JobEventCallback? onComplete,
    JobEventCallback? onRetry,
    JobEventCallback? onFail,
  }) async {
    await _worker?.stop();

    _worker = Worker(
      driver: driver,
      queues: queues,
      concurrency: concurrency,
      pollInterval: pollInterval,
    )
      ..onProcess = onProcess
      ..onComplete = onComplete
      ..onRetry = onRetry
      ..onFail = onFail;

    // Start in the background — don't await the future (it completes on stop)
    unawaited(_worker!.start());
  }

  /// Stops the background worker gracefully.
  Future<void> stopWorker() async {
    await _worker?.stop();
    _worker = null;
  }

  /// Returns the number of pending jobs across specified [queues].
  Future<Map<String, int>> pending([List<String> queues = const ['default']]) async {
    final result = <String, int>{};
    for (final q in queues) {
      result[q] = await driver.size(q);
    }
    return result;
  }

  /// Clears all jobs from the specified [queue].
  Future<void> clear([String queue = 'default']) async {
    await driver.clear(queue);
  }
}

// ---------------------------------------------------------------------------
// DI Convenience
// ---------------------------------------------------------------------------

/// Extension on [Container] for queue convenience.
extension QueueContainerExtensions on Container {
  /// Retrieves the registered [Queue] instance.
  Queue get queue => resolve<Queue>();
}
