import 'adapter.dart';
import 'migration.dart';
import '../core/logger.dart';

/// Manages the execution and rollback of database migrations.
class MigrationRunner {
  final DatabaseAdapter _db;
  final List<MigrationEntry> _registry;

  /// Creates a new [MigrationRunner] with the database [db] and a [registry] of migrations.
  MigrationRunner(this._db, this._registry);

  /// Runs all pending migrations that haven't been applied yet.
  Future<void> run() async {
    await _ensureMigrationsTable();
    
    final applied = await _getAppliedMigrations();
    final pending = _registry.where((e) => !applied.contains(e.name)).toList();

    if (pending.isEmpty) {
      Logger.staticInfo('✅ Nothing to migrate.');
      return;
    }

    // Calculate the next batch number ONCE for the entire run
    final batch = await _getNextBatchNumber();

    for (var entry in pending) {
      Logger.staticInfo('🚀 Migrating: ${entry.name}');
      await entry.migration.up(_db);
      await _recordMigration(entry.name, batch);
    }

    Logger.staticInfo('✨ Successfully applied ${pending.length} migration(s) in batch $batch.');
  }

  /// Rolls back the most recent batch of migrations.
  Future<void> rollback() async {
    await _ensureMigrationsTable();
    final last = await _getLastBatch();
    
    if (last.isEmpty) {
      Logger.staticInfo('ℹ️ Nothing to rollback.');
      return;
    }

    for (var name in last) {
      final entry = _registry.firstWhere((e) => e.name == name);
      Logger.staticInfo('⏪ Rolling back: $name');
      await entry.migration.down(_db);
      await _deleteMigration(name);
    }
    
    Logger.staticInfo('✅ Rollback complete.');
  }

  Future<void> _ensureMigrationsTable() async {
    await _db.query('''
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        batch INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<List<String>> _getAppliedMigrations() async {
    final res = await _db.query('SELECT name FROM migrations');
    return res.rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> _getLastBatch() async {
    final res = await _db.query('SELECT name FROM migrations WHERE batch = (SELECT MAX(batch) FROM migrations)');
    return res.rows.map((r) => r['name'] as String).toList();
  }

  Future<int> _getNextBatchNumber() async {
    final res = await _db.query('SELECT MAX(batch) as max_batch FROM migrations');
    return (res.rows.first['max_batch'] as int? ?? 0) + 1;
  }

  Future<void> _recordMigration(String name, int batch) async {
    await _db.query('INSERT INTO migrations (name, batch) VALUES (@name, @batch)', {
      'name': name,
      'batch': batch
    });
  }

  Future<void> _deleteMigration(String name) async {
    await _db.query('DELETE FROM migrations WHERE name = @name', {'name': name});
  }
}

/// Represents a single migration entry in the [MigrationRunner] registry.
class MigrationEntry {
  /// The unique name of the migration (usually a timestamp prefix + title).
  final String name;

  /// The migration instance to execute.
  final Migration migration;

  /// Creates a new [MigrationEntry].
  MigrationEntry(this.name, this.migration);
}
