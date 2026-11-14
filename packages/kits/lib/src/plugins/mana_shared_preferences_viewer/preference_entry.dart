import 'dart:convert';

import 'package:flutter/foundation.dart';

enum PreferenceKind {
  string('String'),
  integer('int'),
  decimal('double'),
  boolean('bool'),
  stringList('List<String>');

  const PreferenceKind(this.label);
  final String label;
  Object parse(String text) {
    switch (this) {
      case .string:
        return text;
      case .integer:
        if (int.tryParse(text.trim()) case final value?) return value;
      case .decimal:
        if (double.tryParse(text.trim()) case final value?
            when value.isFinite) {
          return value;
        }
      case .boolean:
        if (bool.tryParse(text.trim(), caseSensitive: false)
            case final value?) {
          return value;
        }
      case .stringList:
        final value = jsonDecode(text);
        if (value is List && value.every((item) => item is String)) {
          return value.cast<String>();
        }
    }
    throw FormatException('Expected $label');
  }
}

@immutable
class PreferenceEntry {
  const PreferenceEntry(this.key, this.value, this.kind);
  final String key;
  final String value;
  final PreferenceKind kind;
  factory PreferenceEntry.fromValue(String key, Object value) =>
      switch (value) {
        final bool value => PreferenceEntry(key, '$value', .boolean),
        final int value => PreferenceEntry(key, '$value', .integer),
        final double value => PreferenceEntry(key, '$value', .decimal),
        final String value => PreferenceEntry(key, value, .string),
        // Platform codecs may return List<Object?> even for string lists.
        final List value when value.every((item) => item is String) =>
          PreferenceEntry(key, jsonEncode(value), .stringList),
        _ => throw ArgumentError.value(value),
      };
  Object get parsedValue => kind.parse(value);
}
