/// Converts log metadata to safe, serializable values and redacts secrets.
final class LogSanitizer {
  const LogSanitizer();

  static const String redactedValue = '[REDACTED]';

  Map<String, Object?> sanitize(Map<String, Object?> fields) {
    return Map.unmodifiable(
      fields.map(
        (key, value) => MapEntry(key, _sanitizeValue(key: key, value: value)),
      ),
    );
  }

  Object? _sanitizeValue({required String key, required Object? value}) {
    if (_isSensitiveKey(key)) {
      return redactedValue;
    }

    return switch (value) {
      null || bool() || num() || String() => value,
      DateTime() => value.toUtc().toIso8601String(),
      Uri() => _sanitizeUri(value),
      Enum() => value.name,
      Map() => Map.unmodifiable(
        value.map(
          (nestedKey, nestedValue) => MapEntry(
            nestedKey.toString(),
            _sanitizeValue(key: nestedKey.toString(), value: nestedValue),
          ),
        ),
      ),
      Iterable() => List.unmodifiable(
        value.map((item) => _sanitizeValue(key: '', value: item)),
      ),
      _ => value.toString(),
    };
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

    return normalized.contains('password') ||
        normalized.contains('authorization') ||
        normalized.contains('apikey') ||
        normalized.contains('clientsecret') ||
        normalized.contains('privatekey') ||
        normalized.contains('signingkey') ||
        normalized.contains('hashkey') ||
        normalized.contains('cookie') ||
        normalized == 'secret' ||
        normalized == 'credentials' ||
        normalized == 'credential' ||
        normalized == 'token' ||
        normalized.endsWith('accesstoken') ||
        normalized.endsWith('refreshtoken') ||
        normalized.endsWith('idtoken') ||
        normalized.endsWith('sessiontoken') ||
        normalized.endsWith('jwttoken');
  }

  String _sanitizeUri(Uri value) {
    final withoutCredentials = value.replace(userInfo: '').toString();
    final queryIndex = withoutCredentials.indexOf('?');
    final fragmentIndex = withoutCredentials.indexOf('#');
    final cutIndexes = [
      if (queryIndex >= 0) queryIndex,
      if (fragmentIndex >= 0) fragmentIndex,
    ];

    if (cutIndexes.isEmpty) {
      return withoutCredentials;
    }

    cutIndexes.sort();
    return withoutCredentials.substring(0, cutIndexes.first);
  }
}
