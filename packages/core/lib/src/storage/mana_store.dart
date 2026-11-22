import 'package:shared_preferences/shared_preferences.dart';

import 'mana_preferences.dart';
import 'mana_settings.dart';

final class ManaStore implements ManaPreferences {
  SharedPreferences? _prefs;
  final _savedValues = <String, double?>{};
  final String namespace;

  ManaStore({this.namespace = ''});

  String _key(String key) => namespace.isEmpty ? key : '$namespace.$key';

  SharedPreferences get _storage =>
      _prefs ?? (throw StateError('Call load() before accessing preferences.'));

  @override
  Future<ManaSettings> load() async {
    final storage = _prefs ??= await SharedPreferences.getInstance();
    return ManaSettings.fromMap({
      for (final key in const ManaSettings().toMap().keys)
        key: storage.get(_key(key)),
    });
  }

  @override
  Future<void> save(ManaSettings settings) async {
    for (final entry in settings.toMap().entries) {
      if (_savedValues.containsKey(entry.key) &&
          _savedValues[entry.key] == entry.value &&
          read(entry.key) == entry.value) {
        continue;
      }
      await write(entry.key, entry.value);
      _savedValues[entry.key] = entry.value;
    }
  }

  @override
  Object? read(String key) => _storage.get(_key(key));

  @override
  Future<void> write(String key, Object? value) async {
    // SharedPreferences updates its cache even when the platform write fails.
    _savedValues.remove(key);
    key = _key(key);
    final success = await switch (value) {
      null => _storage.remove(key),
      final bool value => _storage.setBool(key, value),
      final int value => _storage.setInt(key, value),
      final double value => _storage.setDouble(key, value),
      final String value => _storage.setString(key, value),
      final List<String> value => _storage.setStringList(key, value),
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unsupported preference type',
      ),
    };
    if (!success) throw StateError('Failed to write preference: $key');
  }

  @override
  Future<void> close() async {
    _prefs = null;
    _savedValues.clear();
  }
}
