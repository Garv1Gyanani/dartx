import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

/// A simple in-memory rate limiter middleware.
class RateLimiter {
  /// The maximum number of requests allowed within the [window].
  final int maxRequests;

  /// The duration window for the rate limit.
  final Duration window;
  
  final Map<String, List<DateTime>> _requests = {};

  /// Creates a new [RateLimiter] instance.
  RateLimiter({this.maxRequests = 100, this.window = const Duration(minutes: 1)});

  /// Returns a [Middleware] that enforces the rate limit.
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
