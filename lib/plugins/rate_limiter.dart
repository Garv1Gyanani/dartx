import '../core/context.dart';
import '../core/middleware.dart';
import '../http/response.dart';

/// A simple in-memory rate limiter middleware.
class RateLimiter {
  /// Creates a new [RateLimiter] instance.
  RateLimiter({this.maxRequests = 100, this.window = const Duration(minutes: 1)});

  /// The maximum number of requests allowed within the [window].
  final int maxRequests;

  /// The duration window for the rate limit.
  final Duration window;
  
  final Map<String, List<DateTime>> _requests = {};

  /// Returns a [Middleware] that enforces the rate limit.
  Middleware handle() {
    return (Context ctx, Next next) async {
      final ip = ctx.request.rawRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
      final now = DateTime.now();
      
      final clientRequests = _requests[ip] ??= [];
      final recentRequests = clientRequests.where((d) => now.difference(d) < window).toList();
      _requests[ip] = recentRequests;
      
      if (recentRequests.length >= maxRequests) {
        return Response(
          statusCode: 429, 
          body: 'Too Many Requests',
          headers: {'Retry-After': window.inSeconds.toString()},
        );
      }
      
      recentRequests.add(now);
      return next();
    };
  }
}
