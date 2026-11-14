import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
