import 'package:shared_preferences/shared_preferences.dart';

import 'preference_entry.dart';

class PreferencesRepository {
  Future<List<PreferenceEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final keys = prefs.getKeys().toList()..sort();
    return [
      for (final key in keys)
        if (prefs.get(key) case final value?)
          PreferenceEntry.fromValue(key, value),
    ];
  }

  Future<void> save(PreferenceEntry? previous, PreferenceEntry next) async {
    if (next.key.trim().isEmpty) throw const FormatException('Key is required');
    final value = next.parsedValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (previous?.key != next.key && prefs.containsKey(next.key)) {
      throw StateError('Key already exists: ${next.key}');
    }
    final success = await switch (value) {
      final bool value => prefs.setBool(next.key, value),
      final int value => prefs.setInt(next.key, value),
      final double value => prefs.setDouble(next.key, value),
      final String value => prefs.setString(next.key, value),
      final List<String> value => prefs.setStringList(next.key, value),
      _ => throw ArgumentError.value(value),
    };
    if (!success) throw StateError('Failed to save ${next.key}');
    // Preserve the old key until the replacement has been successfully persisted.
    if (previous != null &&
        previous.key != next.key &&
        !await prefs.remove(previous.key)) {
      throw StateError(
        'Saved ${next.key}, but could not remove ${previous.key}',
      );
    }
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(key)) {
      throw StateError('Failed to remove $key');
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.clear()) {
      throw StateError('Failed to clear preferences');
    }
  }
}
