import 'mana_settings.dart';

/// Owned and closed by ManaController.
abstract interface class ManaPreferences {
  Future<ManaSettings> load();
  Future<void> save(ManaSettings settings);
  Object? read(String key);
  Future<void> write(String key, Object? value);
  Future<void> close();
}

class MemoryManaPreferences implements ManaPreferences {
  final Map<String, Object?> _values;

  MemoryManaPreferences([Map<String, Object?> values = const {}])
    : _values = {...values};

  @override
  Future<ManaSettings> load() async => ManaSettings.fromMap(_values);

  @override
  Future<void> save(ManaSettings settings) async =>
      _values.addAll(settings.toMap());

  @override
  Object? read(String key) => _values[key];

  @override
  Future<void> write(String key, Object? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> close() async {}
}
