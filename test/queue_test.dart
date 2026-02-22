import 'dart:async';
import 'package:test/test.dart';
import 'package:kronix/kronix.dart';

/// A simple test job that records its execution.
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
    });

    tearDown(() async {
      await queue.stopWorker();
    });

    // ---- Job Tests ----
    test('Job has unique ID and correct defaults', () {
      final job = CounterJob();
      expect(job.id, startsWith('job_'));
      expect(job.status, JobStatus.pending);
      expect(job.attempts, 0);
      expect(job.maxRetries, 3);
      expect(job.queue, 'default');
      expect(job.canRetry, true);
    });

    test('Job.toJson() serializes correctly', () {
      final job = CounterJob('test-label');
      final json = job.toJson();
      expect(json['name'], 'CounterJob');
      expect(json['queue'], 'default');
      expect(json['status'], 'pending');
      expect(json['attempts'], 0);
    });

    // ---- Driver Tests ----
    test('MemoryQueueDriver push/pop/size', () async {
      expect(await driver.size(), 0);

      final job = CounterJob('a');
      await driver.push(job);
      expect(await driver.size(), 1);

      final popped = await driver.pop();
      expect(popped, isNotNull);
      expect(popped!.id, job.id);
      expect(await driver.size(), 0);
    });

    test('MemoryQueueDriver returns null on empty queue', () async {
      expect(await driver.pop(), isNull);
    });

    test('MemoryQueueDriver complete/fail tracking', () async {
      final job1 = CounterJob('1');
      final job2 = CounterJob('2');

      await driver.complete(job1);
      await driver.fail(job2);

      expect(driver.completedJobs.length, 1);
      expect(driver.failedJobs.length, 1);
      expect(job1.status, JobStatus.completed);
      expect(job2.status, JobStatus.failed);
    });

    test('MemoryQueueDriver clear removes all jobs', () async {
      await driver.push(CounterJob('a'));
      await driver.push(CounterJob('b'));
      expect(await driver.size(), 2);

      await driver.clear();
      expect(await driver.size(), 0);
    });

    test('MemoryQueueDriver respects delayed jobs', () async {
      final job = CounterJob('delayed');
      job.availableAt = DateTime.now().add(const Duration(hours: 1));
      await driver.push(job);

      // Should not pop because it's delayed
      expect(await driver.pop(), isNull);
      // But it's still in the queue
      expect(await driver.size(), 1);
    });

    // ---- Queue.dispatch Tests ----
    test('Queue.dispatch adds job to driver', () async {
      final id = await queue.dispatch(CounterJob());
      expect(id, startsWith('job_'));
      expect(await driver.size(), 1);
    });

    test('Queue.dispatchAfter sets availableAt', () async {
      final job = CounterJob();
      await queue.dispatchAfter(const Duration(seconds: 30), job);
      expect(job.availableAt, isNotNull);
      expect(job.availableAt!.isAfter(DateTime.now()), isTrue);
    });

    test('Queue.dispatchSync executes immediately', () async {
      final job = CounterJob('sync');
      await queue.dispatchSync(job);
      expect(CounterJob.counter, 1);
      expect(job.status, JobStatus.completed);
      expect(CounterJob.log, ['executed:sync']);

      // Should NOT go through the driver
      expect(await driver.size(), 0);
    });

    test('Queue.dispatchSync rethrows on failure', () async {
      final job = AlwaysFailJob();
      expect(() => queue.dispatchSync(job), throwsException);
    });

    // ---- Worker Tests ----
    test('Worker processes jobs from queue', () async {
      await queue.dispatch(CounterJob('worker-1'));
      await queue.dispatch(CounterJob('worker-2'));

      await queue.work(pollInterval: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 500));
      await queue.stopWorker();

      expect(CounterJob.counter, 2);
      expect(CounterJob.log, contains('executed:worker-1'));
      expect(CounterJob.log, contains('executed:worker-2'));
    });

    test('Worker retries flakey jobs with backoff', () async {
      await queue.dispatch(FlakeyJob(failTimes: 2));

      await queue.work(pollInterval: const Duration(milliseconds: 50));
      // Wait long enough for retries (50ms + 100ms + processing time)
      await Future.delayed(const Duration(milliseconds: 800));
      await queue.stopWorker();

      expect(FlakeyJob.succeeded, isTrue);
      expect(FlakeyJob.handleCount, 3); // fail, fail, succeed
    });

    test('Worker permanently fails after max retries', () async {
      await queue.dispatch(AlwaysFailJob());

      await queue.work(pollInterval: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 600));
      await queue.stopWorker();

      expect(AlwaysFailJob.permanentlyFailed, isTrue);
      expect(AlwaysFailJob.failureCallbacks, 2); // called on each failure
      expect(driver.failedJobs.length, 1);
    });

    test('Worker processes jobs from custom queues', () async {
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

    test('Worker lifecycle callbacks fire', () async {
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

    // ---- Integration: ctx.queue ----
    test('ctx.queue dispatches from handler', () async {
      final app = App();
      final testQueue = Queue(driver: MemoryQueueDriver());
      di.singleton<Queue>(testQueue);

      app.post('/send-email', (ctx) async {
        final jobId = await ctx.queue.dispatch(CounterJob('from-handler'));
        return ctx.json({'queued': jobId});
      });

      final client = app.test();

      await client.post('/send-email')
        .then((res) => res
          .assertStatus(200)
          .assertBodyContains('queued'));

      await client.stop();
    });
  });
}
