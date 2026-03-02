import 'package:kronix/kronix.dart';

/// Simple User model for demonstration.
class User {
  /// Creates a new [User].
  User(this.id);

  /// The user's unique identifier.
  final int id;
}

void main() async {
  final app = App();

  // Route showing a standard 404
  app.get('/users/:id', (ctx) async {
    final id = int.tryParse(ctx.params['id'] ?? '');
    if (id == null || id > 100) {
      throw NotFoundException('User with ID $id not found');
    }
    return ctx.json(<String, int>{'user': id});
  });

  // Route showing a 403
  app.get('/secret', (ctx) async {
    throw ForbiddenException('You do not have access to the vaults.');
  });

  // Route showing an unhandled error (500)
  app.get('/crash', (ctx) async {
    // This will be caught by the global handler
    throw StateError('This is an unhandled application error!');
  });

  // Toggle this to see difference in 500 responses
  Config.set('APP_ENV', 'development');
  // Config.set('APP_ENV', 'production');

  Logger.level = LogLevel.debug;
  await app.listen(port: 3000);
}
