import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

class RequestSizeLimit {
  final int maxBytes;

  RequestSizeLimit(this.maxBytes);

  Middleware handle() {
    return (Context ctx, Next next) async {
      final contentLength = ctx.request.rawRequest.contentLength;
      
      if (contentLength > maxBytes) {
        return Response(statusCode: 413, body: 'Request Entity Too Large');
      }
      
      return await next();
    };
  }
}
