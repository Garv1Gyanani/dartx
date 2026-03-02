import 'dart:io';
import '../core/middleware.dart';
import 'session.dart';
import 'store.dart';

/// Middleware for managing server-side sessions.
class SessionMiddleware {
  /// Creates a new [SessionMiddleware] instance.
  SessionMiddleware({
    required this.store,
    this.cookieName = 'kronix_session',
    this.ttl = const Duration(hours: 2),
  });

  /// The storage engine used to persist session data.
  final SessionStore store;

  /// The name of the session cookie.
  final String cookieName;

  /// The time-to-live for sessions.
  final Duration ttl;

  /// Returns a [Middleware] that manages the session lifecycle.
  Middleware handle() {
    return (ctx, next) async {
      // 1. Try to get session ID from cookie
      final cookies = ctx.request.rawRequest.cookies;
      final sessionCookie = cookies.firstWhere(
        (c) => c.name == cookieName,
        orElse: () => Cookie(cookieName, ''),
      );

      var sessionId = sessionCookie.value;
      Session session;

      // 2. Load existing or create new session
      if (sessionId.isNotEmpty) {
        final data = await store.get(sessionId);
        if (data != null) {
          session = Session(sessionId, data);
        } else {
          sessionId = Session.generateId();
          session = Session(sessionId);
        }
      } else {
        sessionId = Session.generateId();
        session = Session(sessionId);
      }

      // 3. Attach session to context
      ctx.set('session', session);

      // 4. Continue execution
      final resp = await next();

      // 5. Persist session if it was modified
      if (session.isDirty) {
        await store.put(sessionId, session.data, ttl: ttl);
      }

      // 6. Set/Refresh cookie
      final cookie = Cookie(cookieName, sessionId)
        ..httpOnly = true
        ..path = '/'
        ..maxAge = ttl.inSeconds;
      
      return resp.withCookie(cookie.toString());
    };
  }
}
