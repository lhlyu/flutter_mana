import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/src/widgets/floating_button/icon.dart';

Widget testApp(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (context, _) =>
      FocusScope(autofocus: true, child: Center(child: child)),
);

class TestPlugin extends ManaPluggable {
  @override
  final String name;
  @override
  final bool isSupported;
  @override
  final ManaPresentation presentation;
  final FutureOr<void> Function()? initializeAction;
  final FutureOr<void> Function()? triggerAction;
  final FutureOr<void> Function()? deactivateAction;
  final FutureOr<void> Function()? disposeAction;
  final Widget? barrier;
  int initializationCount = 0;
  int triggerCount = 0;
  int deactivateCount = 0;
  int disposeCount = 0;

  TestPlugin({
    this.name = 'test_plugin',
    this.isSupported = true,
    this.presentation = .window,
    this.initializeAction,
    this.triggerAction,
    this.deactivateAction,
    this.disposeAction,
    this.barrier,
  });

  @override
  String getLocalizedDisplayName(Locale locale) => 'Test plugin';
  @override
  ImageProvider get iconImageProvider => iconImage;

  @override
  Future<void> initialize() async {
    initializationCount++;
    await initializeAction?.call();
  }

  @override
  Future<void> onTrigger() async {
    triggerCount++;
    await triggerAction?.call();
  }

  @override
  Future<void> deactivate() async {
    deactivateCount++;
    await deactivateAction?.call();
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    await disposeAction?.call();
  }

  @override
  Widget? buildWidget(BuildContext context) => presentation == .action
      ? null
      : ManaFloatingWindow(
          name: name,
          barrier: barrier,
          content: presentation == .overlay
              ? null
              : const Text('Plugin content'),
        );
}
