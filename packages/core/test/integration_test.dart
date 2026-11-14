import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/src/widgets/floating_button/index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/helpers.dart';

class _Page extends Page<void> {
  final String label;
  _Page(this.label) : super(key: ValueKey(label));
  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    transitionDuration: .zero,
    reverseTransitionDuration: .zero,
    pageBuilder: (context, animation, secondaryAnimation) => Text(label),
  );
}

class _Router extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  bool details = true;
  @override
  String get currentConfiguration => details ? 'details' : 'home';
  @override
  Future<void> setNewRoutePath(String configuration) async {}
  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [_Page('Home'), if (details) _Page('Details')],
    onDidRemovePage: (page) {
      details = false;
      notifyListeners();
    },
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'builder uses the host WidgetsApp and does not create a second Navigator',
    (tester) async {
      final runtime = ManaController(preferences: MemoryManaPreferences());
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                builder(context),
          ),
          home: const Text('Host'),
          builder: (context, child) =>
              ManaWidget.builder(controller: runtime, child: child!),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WidgetsApp), findsOneWidget);
      expect(find.byType(Navigator), findsOneWidget);
      expect(find.byType(FloatingButton), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(runtime.isClosed, isFalse);
      await runtime.close();
    },
  );

  testWidgets('Navigator observer consumes debug back before host route back', (
    tester,
  ) async {
    final runtime = ManaController(preferences: MemoryManaPreferences());
    final observer = ManaNavigatorObserver(runtime);
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        navigatorKey: key,
        navigatorObservers: [observer],
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          transitionDuration: .zero,
          reverseTransitionDuration: .zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        ),
        home: const Text('Home'),
        builder: (context, child) =>
            ManaWidget.builder(controller: runtime, child: child!),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.push(
      PageRouteBuilder<void>(
        transitionDuration: .zero,
        reverseTransitionDuration: .zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Text('Details'),
      ),
    );
    await tester.pumpAndSettle();
    runtime.openPluginPanel();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(runtime.state.pluginPanelVisible, isFalse);
    expect(find.text('Details'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    observer.dispose();
    await tester.pumpWidget(const SizedBox());
    await runtime.close();
  });

  testWidgets(
    'Router dispatcher defers host navigation until debug actions finish',
    (tester) async {
      final runtime = ManaController(preferences: MemoryManaPreferences());
      final dispatcher = RootBackButtonDispatcher();
      final router = _Router();
      await tester.pumpWidget(
        WidgetsApp.router(
          color: const Color(0xFFFFFFFF),
          routerDelegate: router,
          backButtonDispatcher: dispatcher,
          builder: (context, child) => ManaWidget.builder(
            controller: runtime,
            backButtonDispatcher: dispatcher,
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      runtime.openPluginPanel();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(runtime.state.pluginPanelVisible, isFalse);
      expect(router.details, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.details, isFalse);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await runtime.close();
    },
  );

  testWidgets('owned controller releases plugins when its host is unmounted', (
    tester,
  ) async {
    final plugin = TestPlugin();
    await tester.pumpWidget(
      ManaWidget(plugins: [plugin], child: const Text('Host')),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pump();
    expect(plugin.disposeCount, 1);
  });

  testWidgets(
    'separate embedded controllers have distinct roots and sessions',
    (tester) async {
      final first = ManaController(preferences: MemoryManaPreferences());
      final second = ManaController(preferences: MemoryManaPreferences());
      await tester.pumpWidget(
        testApp(
          Row(
            children: [
              Expanded(
                child: ManaWidget.builder(
                  controller: first,
                  child: const Text('First'),
                ),
              ),
              Expanded(
                child: ManaWidget.builder(
                  controller: second,
                  child: const Text('Second'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (index, runtime) in [first, second].indexed) {
        final bounds = tester.getRect(find.byKey(runtime.rootKey));
        final button = tester.getCenter(find.byType(FloatingButton).at(index));
        expect(bounds.contains(button), isTrue);
      }
      first.openPluginPanel();
      await tester.pumpAndSettle();
      expect(first.state.pluginPanelVisible, isTrue);
      expect(second.state.pluginPanelVisible, isFalse);
      expect(first.rootKey.currentContext, isNotNull);
      expect(second.rootKey.currentContext, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await first.close();
      await second.close();
    },
  );
}
