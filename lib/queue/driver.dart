import 'dart:async';
import 'dart:collection';
import 'job.dart';

/// Abstract interface for queue storage backends.
///
/// Implement this to plug in Redis, PostgreSQL, SQS, or any other
/// message broker as a queue backend.
abstract class QueueDriver {
  /// Pushes a [job] onto the specified [queue].
  Future<void> push(Job job, [String queue = 'default']);

  /// Pops the next available job from the [queue].
  /// Returns `null` if the queue is empty or no jobs are available.
  Future<Job?> pop([String queue = 'default']);

  /// Returns the number of pending jobs in the [queue].
  Future<int> size([String queue = 'default']);

  /// Marks a [job] as completed and removes it from the active set.
  Future<void> complete(Job job);

  /// Returns a [job] to the queue for retry, respecting its [availableAt].
  Future<void> release(Job job);

  /// Permanently removes a failed [job] (moves to dead-letter if applicable).
  Future<void> fail(Job job);

  /// Clears all jobs from the [queue]. Primarily for testing.
  Future<void> clear([String queue = 'default']);
}

/// An in-memory [QueueDriver] for development and testing.
///
/// Jobs are stored in Dart collections and are lost when the process exits.
/// For production, use a persistent driver like Redis or PostgreSQL.
class MemoryQueueDriver implements QueueDriver {
  final Map<String, Queue<Job>> _queues = {};
  final List<Job> _failed = [];
  final List<Job> _completed = [];

  Queue<Job> _queue(String name) => _queues.putIfAbsent(name, () => Queue<Job>());

  @override
  Future<void> push(Job job, [String queue = 'default']) async {
    _queue(queue).add(job);
  }

  @override
  Future<Job?> pop([String queue = 'default']) async {
    final q = _queue(queue);
    if (q.isEmpty) return null;

    // Find the first available job (respects delayed/retry scheduling)
    for (int i = 0; i < q.length; i++) {
      final job = q.removeFirst();
      if (job.isAvailable) return job;
      // Not yet available, put it back at the end
      q.add(job);
    }

    return null; // All jobs are delayed
  }

  @override
  Future<int> size([String queue = 'default']) async => _queue(queue).length;

  @override
  Future<void> complete(Job job) async {
    job.status = JobStatus.completed;
    _completed.add(job);
  }

  @override
  Future<void> release(Job job) async {
    final q = _queue(job.queue);
    q.add(job);
  }

  @override
  Future<void> fail(Job job) async {
    job.status = JobStatus.failed;
    _failed.add(job);
  }

  @override
  Future<void> clear([String queue = 'default']) async {
    _queue(queue).clear();
  }

  /// Returns completed jobs (for testing/inspection).
  List<Job> get completedJobs => List.unmodifiable(_completed);

  /// Returns permanently failed jobs (for testing/inspection).
  List<Job> get failedJobs => List.unmodifiable(_failed);
}
