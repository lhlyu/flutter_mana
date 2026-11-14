import 'package:shared_preferences/shared_preferences.dart';

import 'mana_preferences.dart';
import 'mana_settings.dart';

/// Default preferences adapter. No singleton or publicly exposed SharedPreferences handle.
final class ManaStore implements ManaPreferences {
  SharedPreferences? _prefs;
  final String namespace;

  ManaStore({this.namespace = ''});

  String _key(String key) => namespace.isEmpty ? key : '$namespace.$key';

  SharedPreferences get _storage =>
      _prefs ?? (throw StateError('Call load() before accessing preferences.'));

  @override
  Future<ManaSettings> load() async {
    final storage = _prefs ??= await SharedPreferences.getInstance();
    return ManaSettings.fromMap({
      for (final key in storage.getKeys())
        if (namespace.isEmpty || key.startsWith('$namespace.'))
          (namespace.isEmpty ? key : key.substring(namespace.length + 1)):
              storage.get(key),
    });
  }

  @override
  Future<void> save(ManaSettings settings) async {
    for (final entry in settings.toMap().entries) {
      await write(entry.key, entry.value);
    }
  }

  @override
  Object? read(String key) => _storage.get(_key(key));

  @override
  Future<void> write(String key, Object? value) async {
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
  Future<void> close() async => _prefs = null;
}
