import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RecordingStore extends InMemorySharedPreferencesStore {
  _RecordingStore() : super.empty();
  final writes = <String>[];
  bool failNextWrite = false;

  bool _record(String key) {
    writes.add(key);
    if (!failNextWrite) return true;
    failNextWrite = false;
    return false;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      _record(key) && await super.setValue(valueType, key, value);

  @override
  Future<bool> remove(String key) async =>
      _record(key) && await super.remove(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'saving settings writes only changed values after the first save',
    () async {
      final platform = _RecordingStore();
      SharedPreferencesStorePlatform.instance = platform;
      final adapter = ManaStore(namespace: 'runtime');
      addTearDown(adapter.close);
      await adapter.load();
      const initial = ManaSettings(buttonSize: 60);
      await adapter.save(initial);
      platform.writes.clear();
      final next = initial.copyWith(buttonOpacity: .5);
      await adapter.save(next);
      expect(platform.writes, ['flutter.runtime.mana_floating_button_opacity']);
      platform.writes.clear();
      await adapter.save(next);
      expect(platform.writes, isEmpty);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setDouble('runtime.mana_floating_button_size', 90);
      platform.writes.clear();
      await adapter.save(next);
      expect(platform.writes, ['flutter.runtime.mana_floating_button_size']);
      expect(preferences.getDouble('runtime.mana_floating_button_size'), 60);
    },
  );

  for (final remove in [false, true]) {
    test(
      'failed ${remove ? 'coordinate removal' : 'setting write'} is retried despite the preference cache',
      () async {
        final platform = _RecordingStore();
        SharedPreferencesStorePlatform.instance = platform;
        final adapter = ManaStore();
        addTearDown(adapter.close);
        await adapter.load();
        final initial = ManaSettings.fromMap({
          'mana_floating_button_size': 60,
          'mana_floating_button_x': 10,
          'mana_floating_button_y': 20,
        });
        await adapter.save(initial);
        final next = remove
            ? const ManaSettings(buttonSize: 60)
            : initial.copyWith(buttonSize: 80);
        platform.failNextWrite = true;
        await expectLater(adapter.save(next), throwsStateError);
        final key = remove
            ? 'mana_floating_button_x'
            : 'mana_floating_button_size';
        expect(adapter.read(key), remove ? isNull : 80);
        expect((await platform.getAll())['flutter.$key'], remove ? 10 : 60);
        platform.writes.clear();
        await adapter.save(next);
        expect(platform.writes, contains('flutter.$key'));
        expect((await platform.getAll())['flutter.$key'], remove ? isNull : 80);
      },
    );
  }

  test('namespaces isolate persisted runtime and plugin settings', () async {
    final first = ManaStore(namespace: 'first');
    final second = ManaStore(namespace: 'second');
    await first.load();
    await second.load();
    await first.save(const ManaSettings(buttonSize: 60));
    await second.save(const ManaSettings(buttonSize: 80));
    await first.write('plugin.enabled', true);
    expect(second.read('plugin.enabled'), isNull);
    await second.write('plugin.enabled', false);
    expect(first.read('plugin.enabled'), isTrue);
    expect(second.read('plugin.enabled'), isFalse);
    expect((await first.load()).buttonSize, 60);
    expect((await second.load()).buttonSize, 80);
    await first.close();
    await second.close();
  });

  test(
    'saving a null position removes previously persisted coordinates',
    () async {
      final adapter = ManaStore();
      await adapter.load();
      await adapter.save(
        ManaSettings.fromMap({
          'mana_floating_button_x': 10,
          'mana_floating_button_y': 20,
        }),
      );
      expect((await adapter.load()).buttonPosition, isNotNull);
      await adapter.save(const ManaSettings());
      expect((await adapter.load()).buttonPosition, isNull);
      expect(adapter.read('mana_floating_button_x'), isNull);
      expect(adapter.read('mana_floating_button_y'), isNull);
      await adapter.close();
    },
  );

  test('default namespace preserves existing keys and validates platform value types', () async {
    SharedPreferences.setMockInitialValues({'mana_floating_button_size': 70.0});
    final adapter = ManaStore();
    expect((await adapter.load()).buttonSize, 70);
    await adapter.write('tags', ['one', 'two']);
    expect(adapter.read('tags'), ['one', 'two']);
    await expectLater(
      adapter.write('unsupported', {'map': true}),
      throwsArgumentError,
    );
    await adapter.close();
    expect(() => adapter.read('tags'), throwsStateError);
  });
}
