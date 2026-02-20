import 'context.dart';
import '../http/response.dart';

abstract class FormRequest {
  Map<String, String> rules();
  Map<String, String> messages() => {};
}

typedef RuleHandler = bool Function(dynamic value, String? arg);

class Validator {
  /// Registry of validation rules. Can be extended by users.
  static final Map<String, RuleHandler> ruleHandlers = {
    'required': (val, _) => val != null && val.toString().trim().isNotEmpty,
    'email': (val, _) {
      if (val == null || val.toString().isEmpty) return true; // Let 'required' handle empty
      return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
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
      if (val is bool) return true;
      final s = val.toString().toLowerCase();
      return s == 'true' || s == 'false' || s == '1' || s == '0';
    },
    'in': (val, arg) {
      if (val == null || arg == null) return true;
      final options = arg.split(',');
      return options.contains(val.toString());
    },
    'not_in': (val, arg) {
      if (val == null || arg == null) return true;
      final options = arg.split(',');
      return !options.contains(val.toString());
    },
    'url': (val, _) {
      if (val == null || val.toString().isEmpty) return true;
      return Uri.tryParse(val.toString())?.hasAbsolutePath ?? false;
    },
    'integer': (val, _) {
      if (val == null) return true;
      return int.tryParse(val.toString()) != null;
    },
    'string': (val, _) => val is String,
    'array': (val, _) => val is List,
    'alpha': (val, _) => val == null || RegExp(r'^[a-zA-Z]+$').hasMatch(val.toString()),
    'alpha_num': (val, _) => val == null || RegExp(r'^[a-zA-Z0-9]+$').hasMatch(val.toString()),
    'regex': (val, arg) => val == null || arg == null || RegExp(arg).hasMatch(val.toString()),
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

        final handler = ruleHandlers[ruleName];
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
      case 'integer': return 'The $field must be an integer.';
      case 'boolean': return 'The $field field must be true or false.';
      case 'in': return 'The selected $field is invalid.';
      case 'not_in': return 'The selected $field is invalid.';
      case 'url': return 'The $field format is invalid.';
      case 'string': return 'The $field must be a string.';
      case 'array': return 'The $field must be an array.';
      case 'alpha': return 'The $field may only contain letters.';
      case 'alpha_num': return 'The $field may only contain letters and numbers.';
      case 'regex': return 'The $field format is invalid.';
      default: return 'The $field field is invalid.';
    }
  }
}
