import 'dart:io';
import 'adapter.dart';
import 'migration.dart';
import '../core/logger.dart';

class MigrationRunner {
  final DatabaseAdapter _db;
  final List<MigrationEntry> _registry;

  MigrationRunner(this._db, this._registry);

  Future<void> run() async {
    await _ensureMigrationsTable();
    
    final applied = await _getAppliedMigrations();
    int count = 0;

    for (var entry in _registry) {
      if (!applied.contains(entry.name)) {
        Logger.staticInfo('🚀 Migrating: ${entry.name}');
        await entry.migration.up(_db);
        await _recordMigration(entry.name);
        count++;
      }
    }

    if (count == 0) {
      Logger.staticInfo('✅ Nothing to migrate.');
    } else {
      Logger.staticInfo('✨ Successfully applied $count migration(s).');
    }
  }

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

  Future<void> _recordMigration(String name) async {
    final res = await _db.query('SELECT MAX(batch) as max_batch FROM migrations');
    final batch = (res.rows.first['max_batch'] as int? ?? 0) + 1;
    await _db.query('INSERT INTO migrations (name, batch) VALUES (@name, @batch)', {
      'name': name,
      'batch': batch
    });
  }

  Future<void> _deleteMigration(String name) async {
    await _db.query('DELETE FROM migrations WHERE name = @name', {'name': name});
  }
}

class MigrationEntry {
  final String name;
  final Migration migration;
  MigrationEntry(this.name, this.migration);
}
