import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

/// Middleware for enforcing a maximum size on incoming request bodies.
class RequestSizeLimit {
  /// Creates a new [RequestSizeLimit] with the specified [maxBytes].
  RequestSizeLimit(this.maxBytes);

  /// The maximum allowed size in bytes.
  final int maxBytes;

  /// Returns a [Middleware] that rejects requests exceeding the size limit.
  Middleware handle() {
    return (Context ctx, Next next) async {
      final contentLength = ctx.request.rawRequest.contentLength;
      
      if (contentLength > maxBytes) {
        return Response(statusCode: 413, body: 'Request Entity Too Large');
      }
      
      return next();
    };
  }
}
