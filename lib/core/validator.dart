import 'dart:async';

/// Interface for classes that define validation rules and messages.
abstract class FormRequest {
  /// Internal constructor for [FormRequest].
  FormRequest();

  /// Returns a map of field names to validation rule strings (e.g., 'required|email').
  Map<String, String> rules();

  /// Returns a map of attribute.rule keys to custom error messages.
  Map<String, String> messages() => {};
}

/// A function that validates a value against an optional argument and the full data map.
typedef RuleHandler = FutureOr<bool> Function(dynamic value, String? arg, Map<String, dynamic> data);

/// Result of a validation operation containing errors and coerced data.
class ValidationResult {
  /// Creates a new [ValidationResult].
  ValidationResult(this.errors, this.data);

  /// A map of field names to lists of error messages.
  final Map<String, List<String>> errors;

  /// The validated and potentially coerced data.
  final Map<String, dynamic> data;

  /// Returns `true` if validation failed.
  bool get fails => errors.isNotEmpty;

  /// Returns `true` if validation passed.
  bool get passes => errors.isEmpty;
}

/// The core validation engine for the Kronix framework.
class Validator {
  /// Internal constructor for [Validator].
  Validator();

  /// Registry of validation rules. Can be extended by users to add custom rules.
  static final Map<String, RuleHandler> ruleHandlers = {
    'required': (val, _, __) {
      if (val == null) return false;
      if (val is String) return val.trim().isNotEmpty;
      if (val is List) return val.isNotEmpty;
      if (val is Map) return val.isNotEmpty;
      return true;
    },
    'email': (val, _, __) {
      if (val == null || val.toString().isEmpty) return true;
      return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
          .hasMatch(val.toString());
    },
    'min': (val, arg, __) {
      if (val == null || arg == null) return true;
      final min = int.tryParse(arg) ?? 0;
      if (val is String) return val.length >= min;
      if (val is num) return val >= min;
      if (val is List) return val.length >= min;
      return true;
    },
    'max': (val, arg, __) {
      if (val == null || arg == null) return true;
      final max = int.tryParse(arg) ?? 0;
      if (val is String) return val.length <= max;
      if (val is num) return val <= max;
      if (val is List) return val.length <= max;
      return true;
    },
    'numeric': (val, _, __) {
      if (val == null) return true;
      return num.tryParse(val.toString()) != null;
    },
    'boolean': (val, _, __) {
      if (val == null) return true;
      if (val is bool) return true;
      final s = val.toString().toLowerCase();
      return s == 'true' || s == 'false' || s == '1' || s == '0';
    },
    'in': (val, arg, __) {
      if (val == null || arg == null) return true;
      final options = arg.split(',');
      return options.contains(val.toString());
    },
    'not_in': (val, arg, __) {
      if (val == null || arg == null) return true;
      final options = arg.split(',');
      return !options.contains(val.toString());
    },
    'url': (val, _, __) {
      if (val == null || val.toString().isEmpty) return true;
      final uri = Uri.tryParse(val.toString());
      return uri != null && uri.hasScheme && uri.hasAuthority;
    },
    'integer': (val, _, __) {
      if (val == null) return true;
      return int.tryParse(val.toString()) != null;
    },
    'string': (val, _, __) => val is String,
    'array': (val, _, __) => val is List,
    'alpha': (val, _, __) => val == null || RegExp(r'^[a-zA-Z]+$').hasMatch(val.toString()),
    'alpha_num': (val, _, __) =>
        val == null || RegExp(r'^[a-zA-Z0-9]+$').hasMatch(val.toString()),
    'regex': (val, arg, __) {
      if (val == null || arg == null) return true;
      try {
        return RegExp(arg).hasMatch(val.toString());
      } catch (_) {
        return false;
      }
    },
    'confirmed': (val, arg, data) {
      final fieldToCompare = arg ?? 'password_confirmation';
      return val == data[fieldToCompare];
    },
  };

  /// Validates the [data] against the provided [rules].
  static Future<ValidationResult> validate(
    Map<String, dynamic> data,
    Map<String, String> rules, [
    Map<String, String>? customMessages,
  ]) async {
    final errors = <String, List<String>>{};
    final validatedData = <String, dynamic>{};

    // 1. Expand wildcards (e.g. items.*.name)
    final expandedRules = <String, String>{};
    for (final entry in rules.entries) {
      if (entry.key.contains('*')) {
        final matches = _expandWildcardPath(data, entry.key);
        for (final match in matches) {
          expandedRules[match] = entry.value;
        }
      } else {
        expandedRules[entry.key] = entry.value;
      }
    }

    // 2. Process all rules (including expanded ones)
    for (final entry in expandedRules.entries) {
      final field = entry.key;
      final ruleString = entry.value;
      final fieldRules = ruleString.split('|');
      final value = _getNestedValue(data, field);

      var fieldFailed = false;
      final shouldBail = fieldRules.contains('bail');

      for (final rule in fieldRules) {
        if (rule == 'bail') continue;

        var ruleName = rule;
        String? arg;
        if (rule.contains(':')) {
          final parts = rule.split(':');
          ruleName = parts[0];
          arg = parts[1];
        }

        final handler = ruleHandlers[ruleName];
        if (handler != null) {
          final passed = await handler(value, arg, data);
          if (!passed) {
            final message = _getMessage(field, ruleName, arg, customMessages);
            errors[field] ??= [];
            errors[field]!.add(message);
            fieldFailed = true;

            // Short-circuit on first failure if bail is set or if required fails
            if (shouldBail || ruleName == 'required') break;
          }
        }
      }

      if (!fieldFailed) {
        _setNestedValue(validatedData, field, _coerceValue(value, fieldRules));
      }
    }

    return ValidationResult(errors, validatedData);
  }

  /// Expands a wildcard path into concrete paths based on the [data].
  /// E.g. "items.*.name" -> ["items.0.name", "items.1.name"]
  static List<String> _expandWildcardPath(dynamic data, String path) {
    if (!path.contains('*')) return [path];

    final segments = path.split('.');
    var results = <String>[''];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final nextResults = <String>[];

      for (final currentPath in results) {
        final prefix = currentPath.isEmpty ? '' : '$currentPath.';

        if (segment == '*') {
          // Resolve actual data to see how many items we have
          final resolved = _getNestedValue(data, currentPath);
          if (resolved is List) {
            for (var index = 0; index < resolved.length; index++) {
              nextResults.add('$prefix$index');
            }
          }
        } else {
          nextResults.add('$prefix$segment');
        }
      }
      results = nextResults;
    }

    return results;
  }

  static dynamic _getNestedValue(dynamic data, String path) {
    if (path.isEmpty) return data;
    if (!path.contains('.')) {
      if (data is Map) return data[path];
      if (data is List) {
        final index = int.tryParse(path);
        if (index != null && index >= 0 && index < data.length) return data[index];
      }
      return null;
    }

    dynamic current = data;
    for (final segment in path.split('.')) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else if (current is List) {
        final index = int.tryParse(segment);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  static void _setNestedValue(Map<String, dynamic> data, String path, dynamic value) {
    if (!path.contains('.')) {
      data[path] = value;
      return;
    }

    final segments = path.split('.');
    dynamic current = data;
    for (var i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      final nextSegment = segments[i + 1];
      final isNextIndex = int.tryParse(nextSegment) != null;

      if (current is Map) {
        current = current.putIfAbsent(
          segment,
          () => isNextIndex ? <dynamic>[] : <String, dynamic>{},
        );
      } else if (current is List) {
        final index = int.parse(segment);
        while (current.length <= index) {
          current.add(isNextIndex ? <dynamic>[] : <String, dynamic>{});
        }
        current = current[index];
      }
    }

    final lastSegment = segments.last;
    if (current is Map) {
      current[lastSegment] = value;
    } else if (current is List) {
      final index = int.parse(lastSegment);
      while (current.length <= index) {
        current.add(null);
      }
      current[index] = value;
    }
  }

  static dynamic _coerceValue(dynamic value, List<String> rules) {
    if (value == null) return null;

    if (rules.contains('integer')) {
      return int.tryParse(value.toString()) ?? value;
    }
    if (rules.contains('numeric')) {
      return num.tryParse(value.toString()) ?? value;
    }
    if (rules.contains('boolean')) {
      final s = value.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return value;
  }

  static String _getMessage(
    String field,
    String rule,
    String? arg,
    Map<String, String>? customMessages,
  ) {
    final key = '$field.$rule';
    if (customMessages != null && customMessages.containsKey(key)) {
      return customMessages[key]!;
    }

    switch (rule) {
      case 'required':
        return 'The $field field is required.';
      case 'email':
        return 'The $field must be a valid email address.';
      case 'min':
        return 'The $field must be at least $arg.';
      case 'max':
        return 'The $field may not be greater than $arg.';
      case 'numeric':
        return 'The $field must be a number.';
      case 'integer':
        return 'The $field must be an integer.';
      case 'boolean':
        return 'The $field field must be true or false.';
      case 'in':
        return 'The selected $field is invalid.';
      case 'not_in':
        return 'The selected $field is invalid.';
      case 'url':
        return 'The $field format is invalid.';
      case 'string':
        return 'The $field must be a string.';
      case 'array':
        return 'The $field must be an array.';
      case 'alpha':
        return 'The $field may only contain letters.';
      case 'alpha_num':
        return 'The $field may only contain letters and numbers.';
      case 'regex':
        return 'The $field format is invalid.';
      case 'confirmed':
        return 'The $field confirmation does not match.';
      default:
        return 'The $field field is invalid.';
    }
  }
}
