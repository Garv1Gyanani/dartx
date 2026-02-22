import 'dart:math';

/// The current state of a [Job] in the queue lifecycle.
enum JobStatus { pending, processing, completed, failed }

/// Base class for all queueable jobs.
///
/// Extend this class and implement [handle] to define the work
/// your job performs. Override [maxRetries], [retryDelay], and [queue]
/// to control retry behaviour and queue routing.
///
/// ```dart
/// class SendEmailJob extends Job {
///   final String to;
///   final String subject;
///   SendEmailJob(this.to, this.subject);
///
///   @override
///   String get name => 'SendEmailJob';
///
///   @override
///   int get maxRetries => 3;
///
///   @override
///   Future<void> handle() async {
///     await emailService.send(to, subject);
///   }
/// }
/// ```
abstract class Job {
  /// A unique ID generated for each job instance.
  late final String id;

  /// The logical name of this job, used for logging and tracking.
  String get name;

  /// The queue this job should be dispatched to. Defaults to `'default'`.
  String get queue => 'default';

  /// Maximum number of times this job can be retried after failure.
  int get maxRetries => 3;

  /// Base delay between retries. Actual delay increases exponentially.
  Duration get retryDelay => const Duration(seconds: 2);

  /// How many times this job has been attempted so far.
  int attempts = 0;

  /// The current status of this job.
  JobStatus status = JobStatus.pending;

  /// The error from the last failed attempt, if any.
  Object? lastError;

  /// The stack trace from the last failed attempt, if any.
  StackTrace? lastStackTrace;

  /// When this job was first created.
  late final DateTime createdAt;

  /// When this job should next be processed (for delayed/retry scheduling).
  DateTime? availableAt;

  Job() {
    id = _generateId();
    createdAt = DateTime.now();
  }

  /// The work this job performs. Override in your subclass.
  Future<void> handle();

  /// Called when [handle] throws an exception. Override for custom error handling.
  Future<void> onFailure(Object error, StackTrace stackTrace) async {}

  /// Called after the job has exhausted all retries. Override for dead-letter logic.
  Future<void> onPermanentFailure(Object error, StackTrace stackTrace) async {}

  /// Calculates the delay for the current retry attempt using exponential backoff.
  Duration get currentRetryDelay {
    final multiplier = 1 << (attempts - 1); // 1, 2, 4, 8, ...
    return retryDelay * multiplier;
  }

  /// Returns true if this job can be retried.
  bool get canRetry => attempts < maxRetries;

  /// Returns true if this job is ready to be processed now.
  bool get isAvailable =>
      availableAt == null || DateTime.now().isAfter(availableAt!);

  static String _generateId() {
    final rnd = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'job_${ts}_$rand';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'queue': queue,
        'status': status.name,
        'attempts': attempts,
        'maxRetries': maxRetries,
        'createdAt': createdAt.toIso8601String(),
        'availableAt': availableAt?.toIso8601String(),
        'lastError': lastError?.toString(),
      };
}
