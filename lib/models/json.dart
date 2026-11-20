// Small helpers for reading loosely-typed JSON from the API safely.

double asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String asString(Object? value, [String fallback = '']) => value == null ? fallback : '$value';

DateTime? asDate(Object? value) => value == null ? null : DateTime.tryParse('$value');

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> asList(Object? value) => value is List ? value : const [];

/// A reference field may be a populated object (`{"_id": ..., "name": ...}`) or just an id string.
String? refId(Object? value) {
  if (value == null) return null;
  if (value is Map) return value['_id']?.toString();
  return '$value';
}

String? refName(Object? value) => value is Map ? value['name']?.toString() : null;
