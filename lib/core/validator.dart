import 'context.dart';
import '../http/response.dart';

abstract class FormRequest {
  Map<String, String> rules();
  Map<String, String> messages() => {};
}

class Validator {
  static final Map<String, bool Function(dynamic value, String? arg)> _ruleHandlers = {
    'required': (val, _) => val != null && val.toString().trim().isNotEmpty,
    'email': (val, _) {
      if (val == null || val.toString().isEmpty) return true; // Let 'required' handle empty
      return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(val.toString());
    },
    'min': (val, arg) {
      if (val == null || arg == null) return true;
      final min = int.tryParse(arg) ?? 0;
      if (val is String) return val.length >= min;
      if (val is num) return val >= min;
      if (val is List) return val.length >= min;
      return true;
    },
    'max': (val, arg) {
      if (val == null || arg == null) return true;
      final max = int.tryParse(arg) ?? 0;
      if (val is String) return val.length <= max;
      if (val is num) return val <= max;
      if (val is List) return val.length <= max;
      return true;
    },
    'numeric': (val, _) {
      if (val == null) return true;
      return num.tryParse(val.toString()) != null;
    },
    'boolean': (val, _) {
      if (val == null) return true;
      return val is bool || val == 'true' || val == 'false' || val == 1 || val == 0;
    },
  };

  static Map<String, List<String>> validate(Map<String, dynamic> data, Map<String, String> rules, [Map<String, String>? customMessages]) {
    final Map<String, List<String>> errors = {};

    rules.forEach((field, ruleString) {
      final fieldRules = ruleString.split('|');
      final value = data[field];

      for (var rule in fieldRules) {
        String ruleName = rule;
        String? arg;

        if (rule.contains(':')) {
          final parts = rule.split(':');
          ruleName = parts[0];
          arg = parts[1];
        }

        final handler = _ruleHandlers[ruleName];
        if (handler != null) {
          if (!handler(value, arg)) {
            final message = _getMessage(field, ruleName, arg, customMessages);
            errors[field] ??= [];
            errors[field]!.add(message);
          }
        }
      }
    });

    return errors;
  }

  static String _getMessage(String field, String rule, String? arg, Map<String, String>? customMessages) {
    final key = '$field.$rule';
    if (customMessages != null && customMessages.containsKey(key)) {
      return customMessages[key]!;
    }

    switch (rule) {
      case 'required': return 'The $field field is required.';
      case 'email': return 'The $field must be a valid email address.';
      case 'min': return 'The $field must be at least $arg.';
      case 'max': return 'The $field may not be greater than $arg.';
      case 'numeric': return 'The $field must be a number.';
      case 'boolean': return 'The $field field must be true or false.';
      default: return 'The $field field is invalid.';
    }
  }
}
