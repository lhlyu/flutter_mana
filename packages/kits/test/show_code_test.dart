import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';
import 'package:flutter_mana_kits/src/plugins/mana_show_code/utils/code_display_service.dart';
import 'package:flutter_mana_kits/src/plugins/mana_show_code/widgets/show_code_content.dart';
import 'package:flutter_mana_kits/src/ui/kit_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'support/host.dart';

class _FirstPage extends StatelessWidget {
  const _FirstPage();
  @override
  Widget build(BuildContext context) => const Text('first');
}

class _SecondPage extends StatefulWidget {
  const _SecondPage();
  @override
  State<_SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<_SecondPage> {
  @override
  Widget build(BuildContext context) => const Text('second');
}

class _Shell extends StatelessWidget {
  const _Shell();
  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateRoute: (_) =>
        PageRouteBuilder<void>(pageBuilder: (_, _, _) => const _SecondPage()),
  );
}

class _SourceVm extends VmInspector {
  bool unavailable = false;
  final sourceLoads = <String>[];
  final classNames = <String, String>{};

  String id(Object object) {
    // IDs represent object identity, not a lookup by class name.
    final id = 'instances/${identityHashCode(object)}';
    classNames[id] = object.runtimeType.toString();
    return id;
  }

  @override
  Future<vm.Obj> getObject(String id, {int? offset, int? count}) async {
    if (id.startsWith('instances/')) {
      return vm.Instance(
        id: id,
        classRef: vm.ClassRef(id: 'classes/${classNames[id]}'),
      );
    }
    if (id.startsWith('classes/')) {
      final name = id.substring('classes/'.length);
      final uri = switch (name) {
        '_FirstPage' => 'package:app/pages/first.dart',
        '_SecondPage' => 'package:app/pages/second.dart',
        '_Shell' => 'package:app/shell.dart',
        _ => 'package:flutter/src/widgets/framework.dart',
      };
      return vm.Class(
        id: id,
        name: name,
        location: vm.SourceLocation(
          script: vm.ScriptRef(id: uri, uri: uri),
        ),
      );
    }
    sourceLoads.add(id);
    return vm.Script(
      id: id,
      uri: id,
      source: unavailable ? null : '// Source of $id',
    );
  }

  @override
  Future<vm.ScriptList> getScripts() =>
      throw StateError('Page lookup must not search all scripts');
}

void main() {
  late _SourceVm inspector;
  late CodeDisplayService service;
  setUp(() {
    inspector = _SourceVm();
    service = CodeDisplayService(inspector: inspector, objectId: inspector.id);
  });

  testWidgets('reads the page definition file directly, not its caller', (
    tester,
  ) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      KeyedSubtree(key: root, child: testHost(const _FirstPage())),
    );
    final page = await service.currentPage(root.currentContext);
    expect(page?.widgetName, '_FirstPage');
    expect(page?.uri, 'package:app/pages/first.dart');
    expect(page?.source, '// Source of package:app/pages/first.dart');
    expect(inspector.sourceLoads, ['package:app/pages/first.dart']);
  });

  testWidgets('push and pop resolve the current route, not retained pages', (
    tester,
  ) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      KeyedSubtree(key: root, child: testHost(const _FirstPage())),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      PageRouteBuilder<void>(pageBuilder: (_, _, _) => const _SecondPage()),
    );
    await tester.pumpAndSettle();
    expect(
      (await service.currentPage(root.currentContext))?.widgetName,
      '_SecondPage',
    );
    navigator.pop();
    await tester.pumpAndSettle();
    expect(
      (await service.currentPage(root.currentContext))?.widgetName,
      '_FirstPage',
    );
    expect(inspector.sourceLoads, [
      'package:app/pages/second.dart',
      'package:app/pages/first.dart',
    ]);
  });

  testWidgets('nested navigators prefer the inner page over its shell', (
    tester,
  ) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      KeyedSubtree(key: root, child: testHost(const _Shell())),
    );
    await tester.pumpAndSettle();
    expect(
      (await service.currentPage(root.currentContext))?.widgetName,
      '_SecondPage',
    );
    expect(inspector.sourceLoads, ['package:app/pages/second.dart']);
  });

  testWidgets('skips Offstage and inactive IndexedStack pages', (tester) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      KeyedSubtree(
        key: root,
        child: testHost(
          Column(
            children: [
              const Offstage(child: _FirstPage()),
              IndexedStack(
                index: 1,
                children: const [_FirstPage(), _SecondPage()],
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      (await service.currentPage(root.currentContext))?.widgetName,
      '_SecondPage',
    );
    expect(inspector.sourceLoads, ['package:app/pages/second.dart']);
  });

  testWidgets('supports a host without a Navigator', (tester) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: KeyedSubtree(key: root, child: const _FirstPage()),
      ),
    );
    expect(
      (await service.currentPage(root.currentContext))?.widgetName,
      '_FirstPage',
    );
  });

  testWidgets('does not inspect Mana sibling overlays', (tester) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      testHost(
        Stack(
          children: [
            KeyedSubtree(key: root, child: const _FirstPage()),
            const _SecondPage(),
          ],
        ),
      ),
    );
    expect(
      (await service.currentPage(root.currentContext))?.widgetName,
      '_FirstPage',
    );
    expect(inspector.sourceLoads, ['package:app/pages/first.dart']);
  });

  testWidgets('missing page shows a message rather than a script search', (
    tester,
  ) async {
    await tester.pumpWidget(testHost(ShowCodeContent(service: service)));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Unable to locate the current page source'),
      findsOneWidget,
    );
    expect(find.byType(EditableText), findsNothing);
    expect(inspector.sourceLoads, isEmpty);
  });

  testWidgets('unavailable source reports an error and can be retried', (
    tester,
  ) async {
    final root = GlobalKey();
    await tester.pumpWidget(
      KeyedSubtree(key: root, child: testHost(const _FirstPage())),
    );
    final host = root.currentContext;
    inspector.unavailable = true;
    // Keep the host mounted while displaying its source in a sibling tool.
    await tester.pumpWidget(
      Stack(
        textDirection: .ltr,
        children: [
          KeyedSubtree(key: root, child: testHost(const _FirstPage())),
          testHost(ShowCodeContent(root: host, service: service)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byWidgetPredicate(
      (widget) => widget is KitButton && widget.label == 'Retry',
    );
    expect(retry, findsOneWidget);
    expect(find.textContaining('Source is unavailable'), findsOneWidget);
    inspector.unavailable = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('// Source of', findRichText: true),
      findsOneWidget,
    );
  });
}
