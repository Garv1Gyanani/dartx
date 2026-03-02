import 'context.dart';
import 'exceptions.dart';
import 'logger.dart';
import 'config.dart';
import '../http/response.dart';

/// Interface for classes that handle global exceptions in the framework.
abstract class ExceptionHandler {
  /// Internal constructor for [ExceptionHandler].
  ExceptionHandler();

  /// Renders a [Response] from the given [error] and [ctx].
  Response render(Context ctx, Object error);
}

/// The default global exception handler for Kronix.
class DefaultExceptionHandler implements ExceptionHandler {
  /// Creates a new [DefaultExceptionHandler].
  DefaultExceptionHandler();

  @override
  Response render(Context ctx, Object error) {
    final logger = Logger.withContext(ctx);
    final isDev = Config.get('APP_ENV', 'development') == 'development';

    if (error is AbortException) {
      return error.response;
    }

    if (error is HttpException) {
      return ctx.json(error.toJson(), status: error.statusCode);
    }

    // Handle unknown exceptions
    logger.error('Unhandled System Error at [${ctx.request.method} ${ctx.request.uri.path}]: $error', error: error);

    final message = isDev ? error.toString() : 'Internal Server Error';
    final stack = isDev && error is Error ? error.stackTrace?.toString() : null;

    return ctx.json({
      'message': message,
      if (stack != null) 'stack': stack,
      if (isDev) 'type': error.runtimeType.toString(),
    }, status: 500);
  }
}
