import 'adapter.dart';

/// Base class for database schema migrations.
/// 
/// Implementing classes should define the [up] and [down] methods to
/// apply and revert schema changes respectively.
abstract class Migration {
  /// Applies the schema changes.
  Future<void> up(DatabaseAdapter db);

  /// Reverts the schema changes.
  Future<void> down(DatabaseAdapter db);
}
