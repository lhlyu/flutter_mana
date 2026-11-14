import 'package:example/demo_session.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/flutter_mana_kits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DemoSession session;
  setUp(() {
    SharedPreferences.setMockInitialValues({'unrelated': 'keep me'});
    session = DemoSession(preferences: MemoryManaPreferences());
  });
  tearDown(() async {
    await session.close();
    session.dispose();
  });

  test('local requests and errors pass through the shared collector', () async {
    for (final scenario in ['GET', 'POST', '404', 'Timeout']) {
      await session.send(scenario);
    }
    expect(session.requests.data.map((response) => response.statusCode), [
      200,
      201,
      404,
      null,
    ]);
    expect(
      session.requests.data.last.extra[ManaDioCollector.errorKey],
      isNotNull,
    );
    expect(session.busy, isFalse);
  });

  test('seeds five types without changing unrelated preferences', () async {
    await session.seedPreferences();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get('example.name'), isA<String>());
    expect(prefs.get('example.count'), isA<int>());
    expect(prefs.get('example.scale'), isA<double>());
    expect(prefs.get('example.enabled'), isA<bool>());
    expect(prefs.get('example.languages'), isA<List<String>>());
    expect(prefs.getString('unrelated'), 'keep me');
  });

  test('logs and debugPrint are captured and resources are released', () async {
    await session.controller.initializePlugins();
    session.writeLogs();
    expect(session.logs.data.length, 5);
    expect(session.logs.data.last.origin.message, contains('[debugPrint]'));
    await session.close();
    expect(session.logs.isDisposed, isTrue);
    expect(session.requests.isDisposed, isTrue);
    expect(session.controller.isClosed, isTrue);
  });
}
