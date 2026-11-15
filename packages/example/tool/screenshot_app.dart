// Debug-only entry point driven by scripts/screenshots.dart on an iOS simulator.
// The normal example entry point never starts this loopback control server.
import 'dart:convert';
import 'dart:io';

import 'package:example/demo_session.dart';
import 'package:example/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  if (!kDebugMode) {
    throw StateError('Screenshots require a native Debug build.');
  }
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final driver = LiveWidgetController(binding);
  final session = DemoSession(preferences: MemoryManaPreferences());
  runApp(ExampleApp(session: session));
  await driver.pump(const Duration(seconds: 1));
  await session.controller.initializePlugins();
  await driver.tap(find.text('中文'));
  await driver.pump(const Duration(milliseconds: 300));
  await session.seedPreferences();
  session.writeLogs();
  for (final scenario in ['GET', 'POST', '404', 'Timeout']) {
    await session.send(scenario);
  }

  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    const int.fromEnvironment('MANA_SCREENSHOT_PORT', defaultValue: 17931),
  );
  stdout.writeln(
    'Screenshot controller: ${server.address.address}:${server.port}',
  );
  TestGesture? heldTouch;

  await for (final request in server) {
    try {
      final params = request.uri.queryParameters;
      switch (request.uri.path) {
        case '/health':
          break;
        case '/prepare':
          if (heldTouch != null) {
            await heldTouch.up();
            heldTouch = null;
          }
          await session.controller.closePlugin();
          session.controller.closePluginPanel();
          FocusManager.instance.primaryFocus?.unfocus();
          await driver.pump(const Duration(milliseconds: 300));
          // Return the demo page to its initial scroll position.
          final scroll = find.byType(SingleChildScrollView).first;
          await driver.drag(scroll, const Offset(0, 1000));
          await driver.pump(const Duration(milliseconds: 500));
          final kit = params['kit']!;
          if (kit == 'mana_grid') {
            await session.controller.preferences.write(
              'mana_grid_show_numbers',
              true,
            );
          }
          if (kit == 'mana_preview') {
            session.controller.openPluginPanel();
          } else {
            if (!await session.controller.activatePlugin(kit)) {
              throw StateError('Cannot activate $kit');
            }
          }
          await driver.pump(const Duration(seconds: 2));
          break;
        case '/tap':
          final key = params['key'];
          final text = params['text'];
          if (key != null || text != null) {
            await driver.tap(
              key != null ? find.byKey(Key(key)) : find.text(text!).first,
            );
          } else {
            await driver.tapAt(
              Offset(double.parse(params['x']!), double.parse(params['y']!)),
            );
          }
          await driver.pump(const Duration(milliseconds: 700));
          break;
        case '/hold':
          heldTouch = await driver.startGesture(
            Offset(double.parse(params['x']!), double.parse(params['y']!)),
          );
          await driver.pump(const Duration(milliseconds: 100));
          break;
        case '/fullscreen':
          session.controller.toggleFullscreen();
          await driver.pump(const Duration(milliseconds: 500));
          break;
        case '/minimize':
          session.controller.minimizeWindow();
          await driver.pump(const Duration(milliseconds: 500));
          break;
        case '/restore':
          session.controller.restoreWindow();
          await driver.pump(const Duration(milliseconds: 500));
          break;
        case '/text':
          final field = find.byType(EditableText).last;
          final state = driver.state<EditableTextState>(field);
          state.widget.controller.text = params['value']!;
          state.widget.onChanged?.call(params['value']!);
          FocusManager.instance.primaryFocus?.unfocus();
          await driver.pump(const Duration(seconds: 1));
          break;
        default:
          throw StateError('Unknown screenshot command: ${request.uri.path}');
      }
      final texts = find.byType(Text).evaluate().map((element) {
        final text = element.widget as Text;
        return text.data ?? text.textSpan?.toPlainText() ?? '';
      }).toList();
      final sample = find.byWidgetPredicate(
        (widget) => widget is RotationTransition && widget.child is Container,
      );
      final sampleCenter = driver.getCenter(sample);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'active': session.controller.state.activePluginId,
          'texts': texts,
          'size': binding.platformDispatcher.views.first.physicalSize
              .toString(),
          'sample': {'x': sampleCenter.dx, 'y': sampleCenter.dy},
        }),
      );
    } catch (error, stack) {
      debugPrint('$error\n$stack');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('$error');
    } finally {
      await request.response.close();
    }
  }
}
