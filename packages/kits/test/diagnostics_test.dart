import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mana_kits/src/diagnostics/debug_session.dart';
import 'package:flutter_mana_kits/src/plugins/mana_memory_info/utils/memory_service.dart';
import 'package:flutter_mana_kits/src/plugins/mana_show_code/code/code_highlighter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'debug leases restore earlier owners and the original nondefault setting',
    () {
      final original = timeDilation;
      timeDilation = 1.5;
      final first = DebugSession();
      final second = DebugSession();
      addTearDown(() {
        first.dispose();
        second.dispose();
        timeDilation = original;
      });
      first.set(.animation, 2.0);
      second.set(.animation, 3.0);
      first.dispose();
      expect(timeDilation, 3);
      second.dispose();
      expect(timeDilation, 1.5);
    },
  );
  test('latest debug override wins and external changes survive release', () {
    final original = debugPaintSizeEnabled;
    final first = DebugSession();
    final second = DebugSession();
    addTearDown(() {
      first.dispose();
      second.dispose();
      debugPaintSizeEnabled = original;
    });
    first.set(.layout, true);
    second.set(.layout, false);
    first.set(.layout, true);
    second.dispose();
    expect(debugPaintSizeEnabled, true);
    debugPaintSizeEnabled = false;
    first.dispose();
    expect(debugPaintSizeEnabled, false);
  });
  test('byte formatting handles unit boundaries', () {
    expect(MemoryService.formatBytes(0), '0 B');
    expect(MemoryService.formatBytes(1023), '1023 B');
    expect(MemoryService.formatBytes(1024), '1.0 KiB');
    expect(MemoryService.formatBytes(1048576), '1.0 MiB');
    expect(MemoryService.formatBytes(1073741824), '1.0 GiB');
  });
  test('highlighting preserves source, nested comments, raw strings and modern Dart syntax', () {
    const source =
        'sealed class Example {\n/* a /* nested */ end */\n final s = r"raw";\n final m = """multi\nline""";\n final x = (1, 2).\$1;\n}\n';
    expect(highlightDart(source).toPlainText(), source);
    expect(
      highlightDart('extension type Id(int value) {}').toPlainText(),
      'extension type Id(int value) {}',
    );
    expect(highlightDart('final a = 1;').toPlainText(), 'final a = 1;');
    expect(
      highlightDart('var b = "unterminated').toPlainText(),
      'var b = "unterminated',
    );
  });
}
