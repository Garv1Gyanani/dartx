import 'dart:async';
import 'package:test/test.dart';
import 'package:kronix/kronix.dart';

// =============================================================================
// Test Jobs
// =============================================================================

/// A simple job that records its execution.
class CounterJob extends Job {
  static int counter = 0;
  static List<String> log = [];

  final String label;

  CounterJob([this.label = 'default']);

  @override
  String get name => 'CounterJob';

  @override
  int get maxRetries => 3;

  @override
  Duration get retryDelay => const Duration(milliseconds: 50);

  @override
  Duration? get timeout => const Duration(seconds: 5);

  @override
  Future<void> handle() async {
    counter++;
    log.add('executed:$label');
  }

  static void reset() {
    counter = 0;
    log = [];
  }
}

/// A job that fails a specific number of times then succeeds.
class FlakeyJob extends Job {
  static int handleCount = 0;
  static bool succeeded = false;
  final int failTimes;

  FlakeyJob({this.failTimes = 2});

  @override
  String get name => 'FlakeyJob';

  @override
  int get maxRetries => 3;

  @override
  Duration get retryDelay => const Duration(milliseconds: 50);

  @override
  Future<void> handle() async {
    handleCount++;
    if (handleCount <= failTimes) {
      throw Exception('Intentional failure #$handleCount');
    }
    succeeded = true;
  }

  static void reset() {
    handleCount = 0;
    succeeded = false;
  }
}

/// A job that always fails and tracks permanent failure callback.
class AlwaysFailJob extends Job {
  static bool permanentlyFailed = false;
  static int failureCallbacks = 0;

  @override
  String get name => 'AlwaysFailJob';

  @override
  int get maxRetries => 2;

  @override
  Duration get retryDelay => const Duration(milliseconds: 30);

  @override
  Future<void> handle() async {
    throw Exception('I always fail');
  }

  @override
  Future<void> onFailure(Object error, StackTrace stackTrace) async {
    failureCallbacks++;
  }

  @override
  Future<void> onPermanentFailure(Object error, StackTrace stackTrace) async {
    permanentlyFailed = true;
  }

  static void reset() {
    permanentlyFailed = false;
    failureCallbacks = 0;
  }
}

/// A job dispatched to a custom queue.
class PriorityJob extends Job {
  static int counter = 0;

  @override
  String get name => 'PriorityJob';

  @override
  String get queue => 'high-priority';

  @override
  Future<void> handle() async {
    counter++;
  }

  static void reset() {
    counter = 0;
  }
}

/// A job that hangs forever (for timeout testing).
class HangingJob extends Job {
  static bool wasInterrupted = false;

  @override
  String get name => 'HangingJob';

  @override
  int get maxRetries => 1;

  @override
  Duration? get timeout => const Duration(milliseconds: 200);

  @override
  Duration get retryDelay => const Duration(milliseconds: 10);

  @override
  Future<void> handle() async {
    // This will hang until the timeout fires
    await Future.delayed(const Duration(seconds: 60));
  }

  @override
  Future<void> onFailure(Object error, StackTrace stackTrace) async {
    if (error is JobTimeoutException) {
      wasInterrupted = true;
    }
  }

  static void reset() {
    wasInterrupted = false;
  }
}

/// A job with no timeout (should run indefinitely).
class NoTimeoutJob extends Job {
  static bool completed = false;

  @override
  String get name => 'NoTimeoutJob';

  @override
  Duration? get timeout => null; // No timeout

  @override
  Future<void> handle() async {
    await Future.delayed(const Duration(milliseconds: 50));
    completed = true;
  }

  static void reset() {
    completed = false;
  }
}

/// A slow job for rate limiting tests.
class SlowCounterJob extends Job {
  static int counter = 0;
  static List<DateTime> timestamps = [];

  @override
  String get name => 'SlowCounterJob';

  @override
  Duration? get timeout => const Duration(seconds: 5);

  @override
  Future<void> handle() async {
    counter++;
    timestamps.add(DateTime.now());
  }

  static void reset() {
    counter = 0;
    timestamps = [];
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('Queue System', () {
    late MemoryQueueDriver driver;
    late Queue queue;

    setUp(() {
      driver = MemoryQueueDriver();
      queue = Queue(driver: driver);
      CounterJob.reset();
      FlakeyJob.reset();
      AlwaysFailJob.reset();
      PriorityJob.reset();
      HangingJob.reset();
      NoTimeoutJob.reset();
      SlowCounterJob.reset();
    });

    tearDown(() async {
      await queue.stopWorker();
    });

    // =========================================================================
    // Job Tests
    // =========================================================================

    group('Job', () {
      test('has unique ID and correct defaults', () {
        final job = CounterJob();
        expect(job.id, startsWith('job_'));
        expect(job.status, JobStatus.pending);
        expect(job.attempts, 0);
        expect(job.maxRetries, 3);
        expect(job.queue, 'default');
        expect(job.canRetry, true);
        expect(job.timeout, const Duration(seconds: 5));
      });

      test('toJson() serializes correctly', () {
        final job = CounterJob('test-label');
        final json = job.toJson();
        expect(json['name'], 'CounterJob');
        expect(json['queue'], 'default');
        expect(json['status'], 'pending');
        expect(json['attempts'], 0);
        expect(json['finishedAt'], isNull);
      });

      test('exponential backoff calculates correctly', () {
        final job = CounterJob();
        job.attempts = 1;
        expect(job.currentRetryDelay, const Duration(milliseconds: 50));
        job.attempts = 2;
        expect(job.currentRetryDelay, const Duration(milliseconds: 100));
        job.attempts = 3;
        expect(job.currentRetryDelay, const Duration(milliseconds: 200));
      });
    });

    // =========================================================================
    // Driver Tests
    // =========================================================================

    group('MemoryQueueDriver', () {
      test('push/pop/size', () async {
        expect(await driver.size(), 0);

        final job = CounterJob('a');
        await driver.push(job);
        expect(await driver.size(), 1);

        final popped = await driver.pop();
        expect(popped, isNotNull);
        expect(popped!.id, job.id);
        expect(await driver.size(), 0);
      });

      test('returns null on empty queue', () async {
        expect(await driver.pop(), isNull);
      });

      test('complete/fail tracking', () async {
        final job1 = CounterJob('1');
        final job2 = CounterJob('2');

        await driver.complete(job1);
        await driver.fail(job2);

        expect(driver.completedJobs.length, 1);
        expect(driver.failedJobs.length, 1);
        expect(job1.status, JobStatus.completed);
        expect(job2.status, JobStatus.failed);
        expect(job1.finishedAt, isNotNull);
        expect(job2.finishedAt, isNotNull);
      });

      test('clear removes all jobs', () async {
        await driver.push(CounterJob('a'));
        await driver.push(CounterJob('b'));
        expect(await driver.size(), 2);

        await driver.clear();
        expect(await driver.size(), 0);
      });

      test('respects delayed jobs', () async {
        final job = CounterJob('delayed');
        job.availableAt = DateTime.now().add(const Duration(hours: 1));
        await driver.push(job);

        expect(await driver.pop(), isNull);
        expect(await driver.size(), 1);
      });
    });

    // =========================================================================
    // Dead Letter Queue Tests
    // =========================================================================

    group('Dead Letter Queue', () {
      test('failed jobs appear in dead letter queue', () async {
        final job = AlwaysFailJob();
        await driver.fail(job);

        final deadLetters = await driver.deadLetterJobs();
        expect(deadLetters.length, 1);
        expect(deadLetters.first['name'], 'AlwaysFailJob');
      });

      test('retryDeadLetter moves job back to queue', () async {
        final job = AlwaysFailJob();
        job.attempts = 2;
        job.lastError = 'test error';
        await driver.fail(job);

        expect(await driver.size(), 0);
        expect((await driver.deadLetterJobs()).length, 1);

        final ok = await driver.retryDeadLetter(job.id);
        expect(ok, isTrue);

        // Job should be back in the queue, reset
        expect(await driver.size(), 1);
        expect((await driver.deadLetterJobs()).length, 0);
      });

      test('retryDeadLetter returns false for unknown job', () async {
        expect(await driver.retryDeadLetter('nonexistent'), isFalse);
      });

      test('clearDeadLetters removes all failed jobs', () async {
        await driver.fail(AlwaysFailJob());
        await driver.fail(AlwaysFailJob());
        expect((await driver.deadLetterJobs()).length, 2);

        await driver.clearDeadLetters();
        expect((await driver.deadLetterJobs()).length, 0);
      });

      test('Queue facade exposes dead letter API', () async {
        await queue.dispatch(AlwaysFailJob());

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 600));
        await queue.stopWorker();

        final deadLetters = await queue.deadLetters();
        expect(deadLetters.length, 1);
        expect(deadLetters.first['name'], 'AlwaysFailJob');

        // Retry it
        final jobId = deadLetters.first['id'] as String;
        final ok = await queue.retryDeadLetter(jobId);
        expect(ok, isTrue);
        expect((await queue.deadLetters()).length, 0);
      });
    });

    // =========================================================================
    // Queue.dispatch Tests
    // =========================================================================

    group('Queue.dispatch', () {
      test('adds job to driver', () async {
        final id = await queue.dispatch(CounterJob());
        expect(id, startsWith('job_'));
        expect(await driver.size(), 1);
      });

      test('dispatchAfter sets availableAt', () async {
        final job = CounterJob();
        await queue.dispatchAfter(const Duration(seconds: 30), job);
        expect(job.availableAt, isNotNull);
        expect(job.availableAt!.isAfter(DateTime.now()), isTrue);
      });

      test('dispatchSync executes immediately', () async {
        final job = CounterJob('sync');
        await queue.dispatchSync(job);
        expect(CounterJob.counter, 1);
        expect(job.status, JobStatus.completed);
        expect(job.finishedAt, isNotNull);
        expect(CounterJob.log, ['executed:sync']);
        expect(await driver.size(), 0);
      });

      test('dispatchSync rethrows on failure', () async {
        final job = AlwaysFailJob();
        expect(() => queue.dispatchSync(job), throwsException);
      });
    });

    // =========================================================================
    // Worker Tests
    // =========================================================================

    group('Worker', () {
      test('processes jobs from queue', () async {
        await queue.dispatch(CounterJob('worker-1'));
        await queue.dispatch(CounterJob('worker-2'));

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 500));
        await queue.stopWorker();

        expect(CounterJob.counter, 2);
        expect(CounterJob.log, contains('executed:worker-1'));
        expect(CounterJob.log, contains('executed:worker-2'));
      });

      test('retries flakey jobs with backoff', () async {
        await queue.dispatch(FlakeyJob(failTimes: 2));

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 800));
        await queue.stopWorker();

        expect(FlakeyJob.succeeded, isTrue);
        expect(FlakeyJob.handleCount, 3);
      });

      test('permanently fails after max retries', () async {
        await queue.dispatch(AlwaysFailJob());

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 600));
        await queue.stopWorker();

        expect(AlwaysFailJob.permanentlyFailed, isTrue);
        expect(AlwaysFailJob.failureCallbacks, 2);
        expect(driver.failedJobs.length, 1);
      });

      test('processes jobs from custom queues', () async {
        await queue.dispatch(PriorityJob());
        await queue.dispatch(PriorityJob());

        await queue.work(
          queues: ['default', 'high-priority'],
          pollInterval: const Duration(milliseconds: 50),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await queue.stopWorker();

        expect(PriorityJob.counter, 2);
      });

      test('lifecycle callbacks fire', () async {
        int processed = 0;
        int completed = 0;

        await queue.dispatch(CounterJob('cb'));

        await queue.work(
          pollInterval: const Duration(milliseconds: 50),
          onProcess: (_) => processed++,
          onComplete: (_) => completed++,
        );
        await Future.delayed(const Duration(milliseconds: 300));
        await queue.stopWorker();

        expect(processed, 1);
        expect(completed, 1);
      });

      test('Queue.pending reports correct counts', () async {
        await queue.dispatch(CounterJob('a'));
        await queue.dispatch(CounterJob('b'));

        final pending = await queue.pending();
        expect(pending['default'], 2);
      });
    });

    // =========================================================================
    // Timeout Tests
    // =========================================================================

    group('Timeout Protection', () {
      test('kills jobs that exceed timeout', () async {
        bool timeoutCallbackFired = false;

        await queue.dispatch(HangingJob());

        await queue.work(
          pollInterval: const Duration(milliseconds: 50),
          onTimeout: (_) => timeoutCallbackFired = true,
        );
        // Wait for timeout (200ms) + retry delay + buffer
        await Future.delayed(const Duration(milliseconds: 800));
        await queue.stopWorker();

        expect(HangingJob.wasInterrupted, isTrue);
        expect(timeoutCallbackFired, isTrue);
      });

      test('jobs with no timeout run normally', () async {
        await queue.dispatch(NoTimeoutJob());

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 300));
        await queue.stopWorker();

        expect(NoTimeoutJob.completed, isTrue);
      });

      test('dispatchSync respects timeout', () async {
        final job = HangingJob();
        expect(
          () => queue.dispatchSync(job),
          throwsA(isA<JobTimeoutException>()),
        );
      });
    });

    // =========================================================================
    // Rate Limiting Tests
    // =========================================================================

    group('Rate Limiting', () {
      test('maxJobsPerSecond limits throughput', () async {
        // Dispatch 10 jobs
        for (int i = 0; i < 10; i++) {
          await queue.dispatch(SlowCounterJob());
        }

        // Rate limit to 3 per second
        await queue.work(
          pollInterval: const Duration(milliseconds: 100),
          maxJobsPerSecond: 3,
        );

        // After 500ms, should have processed at most ~3 jobs (first second's budget)
        await Future.delayed(const Duration(milliseconds: 500));
        final countAfterHalfSecond = SlowCounterJob.counter;
        expect(countAfterHalfSecond, lessThanOrEqualTo(4)); // allow some timing slack

        // After 1.5s, should have more (second second's budget kicks in)
        await Future.delayed(const Duration(milliseconds: 1200));
        await queue.stopWorker();

        expect(SlowCounterJob.counter, greaterThan(3));
      });
    });

    // =========================================================================
    // Metrics Tests
    // =========================================================================

    group('Metrics', () {
      test('tracks dispatched and completed counts', () async {
        await queue.dispatch(CounterJob('m1'));
        await queue.dispatch(CounterJob('m2'));

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 500));
        await queue.stopWorker();

        final stats = queue.stats;
        expect(stats['dispatched'], 2);
        expect(stats['succeeded'], 2);
        expect(stats['failed'], 0);
        expect(stats['averageProcessingTimeMs'], isA<int>());
        expect(stats['failureRatePercent'], 0.0);
      });

      test('tracks failures and retries', () async {
        await queue.dispatch(AlwaysFailJob());

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 600));
        await queue.stopWorker();

        final stats = queue.stats;
        expect(stats['dispatched'], 1);
        expect(stats['retried'], 1); // 1st attempt fails, retries once, then permanently fails
        expect(stats['failed'], 1);
        expect(stats['failureRatePercent'], greaterThan(0));
      });

      test('tracks timeouts', () async {
        await queue.dispatch(HangingJob());

        await queue.work(pollInterval: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 800));
        await queue.stopWorker();

        final stats = queue.stats;
        expect(stats['timedOut'], greaterThan(0));
      });

      test('QueueMetrics computes p95 correctly', () {
        final m = QueueMetrics();
        for (int i = 1; i <= 100; i++) {
          m.recordSuccess(Duration(milliseconds: i));
        }
        // p95 of 1..100 should be ~95
        expect(m.p95ProcessingTimeMs, greaterThanOrEqualTo(95));
        expect(m.p95ProcessingTimeMs, lessThanOrEqualTo(100));
        expect(m.averageProcessingTimeMs, closeTo(50.5, 1));
      });

      test('QueueMetrics reset clears everything', () {
        final m = QueueMetrics();
        m.recordDispatch();
        m.recordSuccess(const Duration(milliseconds: 100));
        m.recordPermanentFailure();
        m.reset();

        expect(m.snapshot['dispatched'], 0);
        expect(m.snapshot['succeeded'], 0);
        expect(m.snapshot['failed'], 0);
      });
    });

    // =========================================================================
    // Integration: ctx.queue
    // =========================================================================

    group('Integration', () {
      test('ctx.queue dispatches from handler', () async {
        final app = App();
        final testQueue = Queue(driver: MemoryQueueDriver());
        di.singleton<Queue>(testQueue);

        app.post('/send-email', (ctx) async {
          final jobId = await ctx.queue.dispatch(CounterJob('from-handler'));
          return ctx.json({'queued': jobId});
        });

        final client = app.test();

        await client.post('/send-email').then((res) => res
            .assertStatus(200)
            .assertBodyContains('queued'));

        await client.stop();
      });
    });
  });
}
