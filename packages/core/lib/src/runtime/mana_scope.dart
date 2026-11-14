import 'package:flutter/widgets.dart';

import 'mana_controller.dart';

class ManaScope extends InheritedNotifier<ManaController> {
  const ManaScope({
    super.key,
    required ManaController controller,
    required super.child,
  }) : super(notifier: controller);

  static ManaController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ManaScope>();
    if (scope == null) throw FlutterError('No ManaScope found in context.');
    return scope.notifier!;
  }

  /// Non-listening access for initState and imperative callbacks.
  static ManaController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ManaScope>();
    if (scope == null) throw FlutterError('No ManaScope found in context.');
    return scope.notifier!;
  }
}
