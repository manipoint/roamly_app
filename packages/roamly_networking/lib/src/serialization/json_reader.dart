/// Validates JSON fields without exposing response values in errors.
///
/// Transport types and bounds belong here. Feature rules and enum mapping
/// remain in the model that owns the API contract.
final class JsonReader {
  JsonReader(Map<String, Object?> json)
    : _json = Map<String, Object?>.unmodifiable(json);

  final Map<String, Object?> _json;

  Object _required(String key) {
    if (!_json.containsKey(key)) {
      throw FormatException('Missing JSON field: $key.');
    }
    final value = _json[key];
    if (value == null) {
      throw FormatException('Null JSON field: $key.');
    }
    return value;
  }

  /// Reads a string; whitespace is preserved unless explicitly trimmed.
  String string(
    String key, {
    bool trim = false,
    int? minLength,
    int? maxLength,
  }) {
    _bounds(minLength, maxLength);
    final value = _required(key);
    if (value is! String) throw FormatException('Expected string: $key.');
    final result = trim ? value.trim() : value;
    _range(result.runes.length, minLength, maxLength, key);
    return result;
  }

  /// Requires an integer; never truncates a floating-point number.
  int integer(String key, {int? min, int? max}) {
    _bounds(min, max);
    final value = _required(key);
    if (value is! int) throw FormatException('Expected integer: $key.');
    _range(value, min, max, key);
    return value;
  }

  /// Accepts JSON integer or floating-point numbers and rejects nonfinite data.
  double number(String key, {double? min, double? max}) {
    _bounds(min, max);
    final value = _required(key);
    if (value is! num) throw FormatException('Expected number: $key.');
    final result = value.toDouble();
    if (!result.isFinite) {
      throw FormatException('Expected finite number: $key.');
    }
    _range(result, min, max, key);
    return result;
  }

  bool boolean(String key) {
    final value = _required(key);
    if (value is! bool) throw FormatException('Expected boolean: $key.');
    return value;
  }

  /// Reads a nested object with string keys.
  Map<String, Object?> object(String key) {
    final value = _required(key);
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException('Expected JSON object: $key.');
    }
    return Map<String, Object?>.unmodifiable(Map<String, Object?>.from(value));
  }

  /// Reads a bounded list and validates each item with a feature-owned parser.
  List<T> list<T>(
    String key, {
    required T Function(Object? value) parseItem,
    int? minLength,
    int? maxLength,
  }) {
    _bounds(minLength, maxLength);
    final value = _required(key);
    if (value is! List) throw FormatException('Expected list: $key.');
    _range(value.length, minLength, maxLength, key);
    return List<T>.unmodifiable(value.map(parseItem));
  }

  /// Allows explicit null while requiring the key by default.
  ///
  /// The callback is evaluated only for non-null values. Set [allowMissing]
  /// only when the API contract permits an absent field.
  T? nullable<T>(String key, T Function() read, {bool allowMissing = false}) {
    if (!_json.containsKey(key) && !allowMissing) {
      throw FormatException('Missing JSON field: $key.');
    }
    return _json[key] == null ? null : read();
  }

  static void _bounds(num? min, num? max) {
    if ((min != null && !min.isFinite) ||
        (max != null && !max.isFinite) ||
        (min != null && max != null && min > max)) {
      throw ArgumentError('Invalid reader bounds.');
    }
  }

  static void _range(num value, num? min, num? max, String key) {
    if ((min != null && value < min) || (max != null && value > max)) {
      throw FormatException('JSON field out of bounds: $key.');
    }
  }

  /// Reads a timezone-qualified API timestamp and returns UTC.
  ///
  /// Rejects invalid calendar dates, clock values, and timezone offsets.
  DateTime dateTime(String key) {
    final value = string(key);
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})T'
      r'(\d{2}):(\d{2}):(\d{2})'
      r'(?:\.(\d{1,6}))?'
      r'(Z|[+-](\d{2}):(\d{2}))$',
    ).firstMatch(value);

    FormatException invalid() =>
        FormatException('Expected valid timezone-qualified timestamp: $key.');

    if (match == null) throw invalid();

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);
    final offsetHour = int.parse(match.group(9) ?? '0');
    final offsetMinute = int.parse(match.group(10) ?? '0');

    if (year < 1 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        hour > 23 ||
        minute > 59 ||
        second > 59 ||
        offsetHour > 23 ||
        offsetMinute > 59) {
      throw invalid();
    }

    final calendarDate = DateTime.utc(year, month, day);
    if (calendarDate.year != year ||
        calendarDate.month != month ||
        calendarDate.day != day) {
      throw invalid();
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw invalid();

    return parsed.toUtc();
  }
}
