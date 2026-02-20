import 'context.dart';
import 'exceptions.dart';
import 'logger.dart';
import 'config.dart';
import '../http/response.dart';

abstract class ExceptionHandler {
  Response render(Context ctx, Object error);
}

class DefaultExceptionHandler implements ExceptionHandler {
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
    logger.error('Unhandled System Error: $error', error: error);

    final message = isDev ? error.toString() : 'Internal Server Error';
    final stack = isDev && error is Error ? error.stackTrace?.toString() : null;

    return ctx.json({
      'message': message,
      if (stack != null) 'stack': stack,
      if (isDev) 'type': error.runtimeType.toString(),
    }, status: 500);
  }
}
