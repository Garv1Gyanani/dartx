import '../core/context.dart';
import '../core/middleware.dart';
import 'adapter.dart';

/// A middleware that wraps the entire request lifecycle in a database transaction.
/// 
/// The active [DatabaseExecutor] is registered in the request-scoped container,
/// allowing any service resolved during this request to participate in the
/// same transaction.
/// 
/// **Behavior:**
/// - **On success**: The transaction is automatically committed.
/// - **On exception**: The transaction is automatically rolled back, and the
///   exception propagates to the error handler.
/// 
/// **Usage in controllers:**
/// ```dart
/// // The executor is the active transaction
/// final tx = ctx.resolve<DatabaseExecutor>();
/// await tx.query('INSERT INTO ...');
/// ```
Middleware transactionMiddleware() {
  return (Context ctx, Next next) async {
    final db = ctx.resolve<DatabaseAdapter>();
    
    return await db.transaction((tx) async {
      // Register the active transaction executor in the request-scoped container.
      // Any QueryBuilder or service that resolves DatabaseExecutor will use this transaction.
      ctx.container.registerInstance<DatabaseExecutor>(tx);
      
      return await next();
    });
  };
}
