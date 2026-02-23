import 'adapter.dart';

/// Base class for database schema migrations.
/// 
/// Implementing classes should define the [up] and [down] methods to
/// apply and revert schema changes respectively.
/// 
/// Each migration is executed within a transaction by the [MigrationRunner].
/// The provided [DatabaseExecutor] is the active transaction scope.
abstract class Migration {
  /// Applies the schema changes within the given transaction scope.
  Future<void> up(DatabaseExecutor db);

  /// Reverts the schema changes within the given transaction scope.
  Future<void> down(DatabaseExecutor db);
}
