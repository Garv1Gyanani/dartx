import 'adapter.dart';
import 'migration.dart';
import '../core/logger.dart';

/// Manages the execution and rollback of database migrations.
/// 
/// Each individual migration is wrapped in a transaction. If a migration
/// fails, only that migration is rolled back and execution stops.
/// An advisory lock is acquired to prevent concurrent migration runs.
class MigrationRunner {
  /// Creates a new [MigrationRunner] with the database [db] and a [registry] of migrations.
  MigrationRunner(this._db, this._registry);

  final DatabaseAdapter _db;
  final List<MigrationEntry> _registry;

  /// The advisory lock ID used to prevent concurrent migration runs.
  /// This should be a unique constant per application.
  static const int _advisoryLockId = 726391;

  /// Runs all pending migrations that haven't been applied yet.
  /// 
  /// Each migration is executed within its own transaction. If a migration
  /// fails, the transaction is rolled back and no further migrations are run.
  Future<void> run() async {
    await _ensureMigrationsTable();
    
    // Acquire advisory lock to prevent concurrent migration runs
    final locked = await _acquireLock();
    if (!locked) {
      Logger.staticWarning('⚠️ Another migration process is running. Skipping.');
      return;
    }

    try {
      final applied = await _getAppliedMigrations();
      final pending = _registry.where((e) => !applied.contains(e.name)).toList();

      if (pending.isEmpty) {
        Logger.staticInfo('✅ Nothing to migrate.');
        return;
      }

      // Calculate the next batch number ONCE for the entire run
      final batch = await _getNextBatchNumber();
      var successCount = 0;

      for (final entry in pending) {
        Logger.staticInfo('🚀 Migrating: ${entry.name}');
        
        try {
          await _db.transaction((tx) async {
            await entry.migration.up(tx);
            await tx.query(
              'INSERT INTO migrations (name, batch) VALUES (@name, @batch)',
              {'name': entry.name, 'batch': batch},
            );
          });
          successCount++;
        } catch (e) {
          Logger.staticWarning(
            '❌ Migration "${entry.name}" failed: $e\n'
            '   Transaction rolled back. $successCount migration(s) were applied before this failure.'
          );
          return; // Stop running further migrations
        }
      }

      Logger.staticInfo('✨ Successfully applied $successCount migration(s) in batch $batch.');
    } finally {
      await _releaseLock();
    }
  }

  /// Rolls back the most recent batch of migrations.
  /// 
  /// Each rollback is wrapped in its own transaction.
  Future<void> rollback() async {
    await _ensureMigrationsTable();
    
    final locked = await _acquireLock();
    if (!locked) {
      Logger.staticWarning('⚠️ Another migration process is running. Skipping rollback.');
      return;
    }

    try {
      final last = await _getLastBatch();
      
      if (last.isEmpty) {
        Logger.staticInfo('ℹ️ Nothing to rollback.');
        return;
      }

      for (final name in last.reversed) {
        final entry = _registry.cast<MigrationEntry?>().firstWhere(
          (e) => e!.name == name,
          orElse: () => null,
        );

        if (entry == null) {
          Logger.staticWarning('⚠️ Migration "$name" not found in registry. Skipping.');
          continue;
        }

        Logger.staticInfo('⏪ Rolling back: $name');
        try {
          await _db.transaction((tx) async {
            await entry.migration.down(tx);
            await tx.query('DELETE FROM migrations WHERE name = @name', {'name': name});
          });
        } catch (e) {
          Logger.staticWarning('❌ Rollback of "$name" failed: $e. Stopping.');
          return;
        }
      }
      
      Logger.staticInfo('✅ Rollback complete.');
    } finally {
      await _releaseLock();
    }
  }

  Future<void> _ensureMigrationsTable() async {
    await _db.query('''
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        batch INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<bool> _acquireLock() async {
    try {
      final result = await _db.query(
        'SELECT pg_try_advisory_lock(@lock_id) as acquired',
        {'lock_id': _advisoryLockId},
      );
      return result.rows.first['acquired'] == true;
    } catch (_) {
      // If advisory locks aren't supported (non-Postgres), proceed without lock
      return true;
    }
  }

  Future<void> _releaseLock() async {
    try {
      await _db.query(
        'SELECT pg_advisory_unlock(@lock_id)',
        {'lock_id': _advisoryLockId},
      );
    } catch (_) {
      // Ignore if not supported
    }
  }

  Future<List<String>> _getAppliedMigrations() async {
    final res = await _db.query('SELECT name FROM migrations ORDER BY id');
    return res.rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> _getLastBatch() async {
    final res = await _db.query(
      'SELECT name FROM migrations WHERE batch = (SELECT MAX(batch) FROM migrations) ORDER BY id'
    );
    return res.rows.map((r) => r['name'] as String).toList();
  }

  Future<int> _getNextBatchNumber() async {
    final res = await _db.query('SELECT MAX(batch) as max_batch FROM migrations');
    return (res.rows.first['max_batch'] as int? ?? 0) + 1;
  }
}

/// Represents a single migration entry in the [MigrationRunner] registry.
class MigrationEntry {
  /// Creates a new [MigrationEntry].
  MigrationEntry(this.name, this.migration);

  /// The unique name of the migration (usually a timestamp prefix + title).
  final String name;

  /// The migration instance to execute.
  final Migration migration;
}
