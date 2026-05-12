class SchemaAdapter {
  const SchemaAdapter._();

  static String asString(
    Object? value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static String? asNullableString(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final String trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final String converted = value.toString().trim();
    return converted.isEmpty ? null : converted;
  }

  static bool asBool(
    Object? value, {
    bool fallback = false,
  }) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final Map<String, dynamic> parsed = <String, dynamic>{};
      value.forEach((Object? key, Object? entryValue) {
        if (key == null) {
          return;
        }
        parsed[key.toString()] = entryValue;
      });
      return parsed;
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> asListOfMaps(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value.map(asMap).where((entry) => entry.isNotEmpty).toList();
  }
}
