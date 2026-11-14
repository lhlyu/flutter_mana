import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/preferences_repository.dart';
import 'package:flutter_mana_kits/src/plugins/mana_shared_preferences_viewer/preference_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'all preference kinds round-trip without runtimeType string guessing',
    () async {
      final repository = PreferencesRepository();
      final entries = [
        const PreferenceEntry('a', '', .string),
        const PreferenceEntry('b', '42', .integer),
        const PreferenceEntry('c', '1.5', .decimal),
        const PreferenceEntry('d', 'FALSE', .boolean),
        const PreferenceEntry('e', '["a", "b"]', .stringList),
      ];
      for (final entry in entries) {
        await repository.save(null, entry);
      }
      final data = await repository.load();
      expect(data.map((entry) => entry.key), ['a', 'b', 'c', 'd', 'e']);
      expect(data.map((entry) => entry.parsedValue), [
        '',
        42,
        1.5,
        false,
        ['a', 'b'],
      ]);
      expect(
        data.map((entry) => entry.kind),
        entries.map((entry) => entry.kind),
      );
    },
  );
  test('platform-decoded string lists load and can be edited', () async {
    // StandardMessageCodec returns List<Object?>, not necessarily List<String>.
    SharedPreferences.setMockInitialValues({
      'languages': <Object?>['English', '中文'],
      'empty': <dynamic>[],
      'name': 'Mana',
    });
    final repository = PreferencesRepository();
    final entries = await repository.load();
    expect(entries.map((entry) => entry.key), ['empty', 'languages', 'name']);
    expect(entries.first.kind, PreferenceKind.stringList);
    expect(entries.first.parsedValue, isEmpty);
    final languages = entries[1];
    expect(languages.kind, PreferenceKind.stringList);
    expect(languages.parsedValue, ['English', '中文']);
    expect(languages.parsedValue, isA<List<String>>());
    await repository.save(
      languages,
      const PreferenceEntry('languages', '["中文", "English"]', .stringList),
    );
    final reloaded = (await repository.load()).firstWhere(
      (entry) => entry.key == 'languages',
    );
    expect(reloaded.parsedValue, ['中文', 'English']);
  });

  test('non-string platform lists are not silently accepted', () {
    for (final value in [
      <Object?>['English', 1],
      <Object?>['中文', null],
      <Object?>[true],
    ]) {
      expect(
        () => PreferenceEntry.fromValue('invalid', value),
        throwsArgumentError,
      );
    }
  });

  test('invalid rename input never removes the existing preference', () async {
    SharedPreferences.setMockInitialValues({'original': 42});
    final repository = PreferencesRepository();
    final previous = (await repository.load()).single;
    await expectLater(
      repository.save(
        previous,
        const PreferenceEntry('new', 'invalid', .integer),
      ),
      throwsFormatException,
    );
    final values = await repository.load();
    expect(values.single.key, 'original');
    expect(values.single.parsedValue, 42);
  });
  test('renames refuse to overwrite unrelated keys', () async {
    SharedPreferences.setMockInitialValues({'a': 'first', 'b': 'second'});
    final repository = PreferencesRepository();
    final previous = (await repository.load()).first;
    await expectLater(
      repository.save(
        previous,
        const PreferenceEntry('b', 'replacement', .string),
      ),
      throwsStateError,
    );
    expect((await repository.load()).map((entry) => entry.value), [
      'first',
      'second',
    ]);
  });
  test('successful rename, deletion and clear are persisted', () async {
    SharedPreferences.setMockInitialValues({'a': true, 'b': 'keep'});
    final repository = PreferencesRepository();
    await repository.save(
      (await repository.load()).first,
      const PreferenceEntry('new', 'false', .boolean),
    );
    expect((await repository.load()).map((entry) => entry.key), ['b', 'new']);
    await repository.remove('new');
    expect((await repository.load()).single.key, 'b');
    await repository.clear();
    expect(await repository.load(), isEmpty);
  });
  test(
    'non-finite doubles, malformed lists and nonboolean input are rejected',
    () {
      for (final text in ['NaN', 'Infinity', '-Infinity', 'abc']) {
        expect(() => PreferenceKind.decimal.parse(text), throwsFormatException);
      }
      for (final text in ['[1]', '{}', 'true', '["a",null]']) {
        expect(
          () => PreferenceKind.stringList.parse(text),
          throwsFormatException,
        );
      }
      expect(() => PreferenceKind.boolean.parse('yes'), throwsFormatException);
      expect(PreferenceKind.boolean.parse(' TRUE '), true);
      expect(PreferenceKind.string.parse(''), '');
    },
  );
}
