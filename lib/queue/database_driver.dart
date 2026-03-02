import 'dart:async';
import '../database/adapter.dart';
import 'driver.dart';
import 'job.dart';

/// A record representing a database-backed job row.
///
/// Used by [DatabaseQueueDriver] to hydrate [Job] instances from the database.
class _JobRow {
  _JobRow({
    required this.id,
    required this.name,
    required this.queue,
    required this.status,
    required this.attempts,
    required this.maxRetries,
    this.lastError,
    this.payload,
    required this.createdAt,
    this.availableAt,
    this.finishedAt,
  });

  factory _JobRow.fromRow(Map<String, dynamic> row) => _JobRow(
        id: row['id'] as String,
        name: row['name'] as String,
        queue: row['queue'] as String,
        status: row['status'] as String,
        attempts: row['attempts'] as int,
        maxRetries: row['max_retries'] as int,
        lastError: row['last_error'] as String?,
        payload: row['payload'] as String?,
        createdAt: row['created_at'] is DateTime
            ? row['created_at'] as DateTime
            : DateTime.parse(row['created_at'].toString()),
        availableAt: row['available_at'] != null
            ? (row['available_at'] is DateTime
                ? row['available_at'] as DateTime
                : DateTime.parse(row['available_at'].toString()))
            : null,
        finishedAt: row['finished_at'] != null
            ? (row['finished_at'] is DateTime
                ? row['finished_at'] as DateTime
                : DateTime.parse(row['finished_at'].toString()))
            : null,
      );

  final String id;
  final String name;
  final String queue;
  final String status;
  final int attempts;
  final int maxRetries;
  final String? lastError;
  final String? payload;
  final DateTime createdAt;
  final DateTime? availableAt;
  final DateTime? finishedAt;
}

/// A factory function that reconstructs a [Job] from its stored name and payload.
///
/// Register one per job type with [DatabaseQueueDriver.registerJobFactory].
typedef JobFactory = Job Function(String? payload);

/// A PostgreSQL (or any SQL database) backed [QueueDriver].
///
/// Uses `SELECT ... FOR UPDATE SKIP LOCKED` for atomic dequeue, preventing
/// double-processing across multiple workers (distributed locking).
///
/// ## Required Table Schema
///
/// ```sql
/// CREATE TABLE IF NOT EXISTS kronix_jobs (
///   id TEXT PRIMARY KEY,
///   name TEXT NOT NULL,
///   queue TEXT NOT NULL DEFAULT 'default',
///   status TEXT NOT NULL DEFAULT 'pending',
///   attempts INTEGER NOT NULL DEFAULT 0,
///   max_retries INTEGER NOT NULL DEFAULT 3,
///   payload TEXT,
///   last_error TEXT,
///   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
///   available_at TIMESTAMPTZ,
///   finished_at TIMESTAMPTZ,
///   reserved_by TEXT
/// );
///
/// CREATE INDEX idx_kronix_jobs_pop ON kronix_jobs(queue, status, available_at);
/// ```
class DatabaseQueueDriver implements QueueDriver {
  /// Creates a new [DatabaseQueueDriver].
  ///
  /// [db] - The database adapter to use.
  /// [table] - The table name (default: `kronix_jobs`).
  /// [workerId] - A unique ID for this worker instance (for lock ownership).
  DatabaseQueueDriver({
    required DatabaseAdapter db,
    String table = 'kronix_jobs',
    String? workerId,
  })  : _db = db,
        _table = table,
        workerId = workerId ?? 'worker_${DateTime.now().millisecondsSinceEpoch}';

  final DatabaseAdapter _db;
  final String _table;

  /// A unique worker identifier used for distributed locking.
  final String workerId;

  final Map<String, JobFactory> _factories = {};

  /// Registers a factory to reconstruct a [Job] of the given [name] from a payload.
  ///
  /// ```dart
  /// driver.registerJobFactory('SendEmailJob', (payload) {
  ///   final data = jsonDecode(payload ?? '{}');
  ///   return SendEmailJob(data['to'], data['subject']);
  /// });
  /// ```
  void registerJobFactory(String name, JobFactory factory) {
    _factories[name] = factory;
  }

  /// Creates the jobs table if it doesn't exist.
  Future<void> createTable() async {
    await _db.query('''
      CREATE TABLE IF NOT EXISTS $_table (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        queue TEXT NOT NULL DEFAULT 'default',
        status TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0,
        max_retries INTEGER NOT NULL DEFAULT 3,
        payload TEXT,
        last_error TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        available_at TIMESTAMPTZ,
        finished_at TIMESTAMPTZ,
        reserved_by TEXT
      )
    ''');
    await _db.query('''
      CREATE INDEX IF NOT EXISTS idx_${_table}_pop
      ON $_table(queue, status, available_at)
    ''');
  }

  @override
  Future<void> push(Job job, [String queue = 'default']) async {
    String? payload;
    final currentJob = job;
    if (currentJob is SerializableJob) {
      payload = currentJob.serialize();
    }

    await _db.query('''
      INSERT INTO $_table (id, name, queue, status, attempts, max_retries, payload, created_at, available_at)
      VALUES (@id, @name, @queue, @status, @attempts, @maxRetries, @payload, @createdAt, @availableAt)
    ''', {
      'id': job.id,
      'name': job.name,
      'queue': queue,
      'status': 'pending',
      'attempts': job.attempts,
      'maxRetries': job.maxRetries,
      'payload': payload,
      'createdAt': job.createdAt,
      'availableAt': job.availableAt,
    });
  }

  @override
  Future<Job?> pop([String queue = 'default']) async {
    // Atomic dequeue with distributed locking:
    // SELECT ... FOR UPDATE SKIP LOCKED ensures no two workers get the same row.
    final result = await _db.query('''
      UPDATE $_table
      SET status = 'processing', reserved_by = @workerId
      WHERE id = (
        SELECT id FROM $_table
        WHERE queue = @queue
          AND status = 'pending'
          AND (available_at IS NULL OR available_at <= NOW())
        ORDER BY created_at ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED
      )
      RETURNING *
    ''', {
      'queue': queue,
      'workerId': workerId,
    });

    if (result.rows.isEmpty) return null;

    final row = _JobRow.fromRow(result.rows.first);
    return _hydrateJob(row);
  }

  @override
  Future<int> size([String queue = 'default']) async {
    final result = await _db.query('''
      SELECT COUNT(*) as count FROM $_table
      WHERE queue = @queue AND status = 'pending'
    ''', {'queue': queue});

    return result.rows.first['count'] as int? ?? 0;
  }

  @override
  Future<void> complete(Job job) async {
    await _db.query('''
      UPDATE $_table
      SET status = 'completed', finished_at = NOW(), reserved_by = NULL
      WHERE id = @id
    ''', {'id': job.id});
  }

  @override
  Future<void> release(Job job) async {
    await _db.query('''
      UPDATE $_table
      SET status = 'pending',
          attempts = @attempts,
          available_at = @availableAt,
          last_error = @lastError,
          reserved_by = NULL
      WHERE id = @id
    ''', {
      'id': job.id,
      'attempts': job.attempts,
      'availableAt': job.availableAt,
      'lastError': job.lastError?.toString(),
    });
  }

  @override
  Future<void> fail(Job job) async {
    await _db.query('''
      UPDATE $_table
      SET status = 'failed',
          finished_at = NOW(),
          last_error = @lastError,
          attempts = @attempts,
          reserved_by = NULL
      WHERE id = @id
    ''', {
      'id': job.id,
      'lastError': job.lastError?.toString(),
      'attempts': job.attempts,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> deadLetterJobs() async {
    final result = await _db.query('''
      SELECT * FROM $_table WHERE status = 'failed'
      ORDER BY finished_at DESC
    ''');
    return result.rows;
  }

  @override
  Future<bool> retryDeadLetter(String jobId) async {
    final result = await _db.query('''
      UPDATE $_table
      SET status = 'pending',
          attempts = 0,
          last_error = NULL,
          available_at = NULL,
          finished_at = NULL,
          reserved_by = NULL
      WHERE id = @id AND status = 'failed'
    ''', {'id': jobId});

    return (result.affectedRows ?? 0) > 0;
  }

  @override
  Future<void> clear([String queue = 'default']) async {
    await _db.query('''
      DELETE FROM $_table WHERE queue = @queue AND status IN ('pending', 'processing')
    ''', {'queue': queue});
  }

  @override
  Future<void> clearDeadLetters() async {
    await _db.query('''
      DELETE FROM $_table WHERE status = 'failed'
    ''');
  }

  /// Returns aggregate metrics from the database.
  Future<Map<String, dynamic>> fetchStats() async {
    final result = await _db.query('''
      SELECT
        status,
        COUNT(*) as count,
        AVG(EXTRACT(EPOCH FROM (finished_at - created_at))) as avg_duration_sec
      FROM $_table
      GROUP BY status
    ''');

    final stats = <String, dynamic>{};
    for (final row in result.rows) {
      stats[row['status'] as String] = {
        'count': row['count'],
        'avgDurationSec': row['avg_duration_sec'],
      };
    }
    return stats;
  }

  /// Recovers stale jobs that were reserved but never completed (worker crashed).
  ///
  /// Any job in 'processing' state for longer than [timeout] is released.
  Future<int> recoverStaleJobs({Duration timeout = const Duration(minutes: 5)}) async {
    final result = await _db.query('''
      UPDATE $_table
      SET status = 'pending', reserved_by = NULL
      WHERE status = 'processing'
        AND available_at < NOW() - INTERVAL '1 second' * @timeoutSeconds
    ''', {'timeoutSeconds': timeout.inSeconds});

    return result.affectedRows ?? 0;
  }

  /// Reconstructs a [Job] from a database row.
  Job _hydrateJob(_JobRow row) {
    final factory = _factories[row.name];
    if (factory == null) {
      throw StateError(
        'No JobFactory registered for "${row.name}". '
        'Call driver.registerJobFactory("${row.name}", ...) before starting the worker.',
      );
    }

    final job = factory(row.payload);
    // Restore state from DB
    _restoreJobState(job, row);
    return job;
  }

  void _restoreJobState(Job job, _JobRow row) {
    // Note: attempts/status in job/row must match.
    job.attempts = row.attempts;
    job.status = JobStatus.values.firstWhere(
      (s) => s.name == row.status, 
      orElse: () => JobStatus.pending,
    );
    job.availableAt = row.availableAt;
    final rError = row.lastError;
    if (rError != null) {
      job.lastError = rError;
    }
  }
}

/// Mixin for jobs that need to persist their constructor arguments.
///
/// Implement [serialize] to encode your job's data, and use a
/// [JobFactory] in [DatabaseQueueDriver.registerJobFactory] to decode it.
///
/// ```dart
/// class SendEmailJob extends Job with SerializableJob {
///   final String to;
///   SendEmailJob(this.to);
///
///   @override
///   String get name => 'SendEmailJob';
///
///   @override
///   String serialize() => jsonEncode({'to': to});
///
///   @override
///   Future<void> handle() async { ... }
/// }
/// ```
mixin SerializableJob on Job {
  /// Serializes this job's data to a string (typically JSON).
  String serialize();
}
