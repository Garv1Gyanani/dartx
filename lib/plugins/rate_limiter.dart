import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Map<String, List<DateTime>> _requests = {};

  RateLimiter({this.maxRequests = 100, this.window = const Duration(minutes: 1)});

  Middleware handle() {
    return (Context ctx, Next next) async {
      final ip = ctx.request.rawRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
      final now = DateTime.now();
      
      _requests[ip] ??= [];
      _requests[ip] = _requests[ip]!.where((d) => now.difference(d) < window).toList();
      
      if (_requests[ip]!.length >= maxRequests) {
        return Response(
          statusCode: 429, 
          body: 'Too Many Requests',
          headers: {'Retry-After': window.inSeconds.toString()},
        );
      }
      
      _requests[ip]!.add(now);
      return await next();
    };
  }
}
