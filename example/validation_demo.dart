import 'package:dartx/dartx.dart';

// 1. Define Request Logic
class LoginRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'email': 'required|email',
    'password': 'required|min:6',
  };

  @override
  Map<String, String> messages() => {
    'email.required': 'Please provide an email to login!',
    'password.min': 'Password must be at least 6 characters long.',
  };
}

void main() async {
  final app = App();

  app.post('/login', (ctx) async {
    // 2. Validate with "The DartX Way"
    // This will automatically throw AbortException with a 422 response if it fails.
    final data = ctx.validate(LoginRequest());
    
    // 3. Logic only runs if validation passes
    return ctx.json({
      'message': 'Login successful!',
      'user': data['email'],
    });
  });

  // Example of manual validation
  app.post('/register', (ctx) async {
    final validated = ctx.validateData({
      'username': 'required|min:3',
      'age': 'numeric',
    });

    return ctx.json({
      'message': 'Registration started',
      'data': validated,
    });
  });

  Logger.level = LogLevel.debug;
  await app.listen(port: 3000);
}
