import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';
import 'adapter.dart';

Middleware transactionMiddleware() {
  return (Context ctx, Next next) async {
    final db = ctx.resolve<DatabaseAdapter>();
    
    try {
      return await db.transaction((tx) async {
        // Register the active transaction in the request-scoped container.
        // This allows services resolved within this request to use the same transaction.
        ctx.container.registerInstance<DatabaseExecutor>(tx);
        
        return await next();
      });
    } catch (e) {
      // Re-throw to let the Exception Transformer handle it.
      // The db.transaction() will handle the rollback automatically on exception.
      rethrow;
    }
  };
}
