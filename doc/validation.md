# Validation in Kronix

Kronix uses a declarative validation system inspired by Laravel.

## Defining Rules

Validation rules are defined as strings separated by a pipe `|`.

```dart
final rules = {
  'email': 'required|email',
  'age': 'numeric|min:18',
  'status': 'in:active,inactive'
};
```

## Using Form Requests

The most professional way to validate is by creating a `FormRequest` class.

```dart
class RegisterRequest extends FormRequest {
  @override
  Map<String, String> rules() => {
    'name': 'required|string',
    'email': 'required|email',
    'password': 'required|min:8'
  };

  @override
  Map<String, String> messages() => {
    'email.required': 'We need your email to create an account!',
  };
}
```

## Validating in Controllers

You can use the `ctx.validate()` method. If validation fails, Kronix automatically throws a `ValidationException` which the framework renders as a **422 Unprocessable Entity** JSON response.

```dart
app.post('/register', (ctx) async {
  final data = ctx.validate(RegisterRequest());
  
  // Logic continues if valid...
  return ctx.json({'status': 'success', 'user': data['name']});
});
```

## Available Rules

- `required`: Field must exist and not be empty.
- `email`: Field must be a valid email address.
- `min:value`: Minimum length (strings/lists) or value (numbers).
- `max:value`: Maximum length or value.
- `numeric`: Must be a number.
- `integer`: Must be an integer.
- `boolean`: Must be true, false, 1, or 0.
- `url`: Must be a valid URL.
- `in:a,b,c`: Must be one of the specified values.
- `not_in:a,b,c`: Must NOT be one of the specified values.
- `string`: Must be a string.
- `array`: Must be a list.
