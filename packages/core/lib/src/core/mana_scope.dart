import 'package:flutter/material.dart';

import 'mana_state.dart';

class ManaScope extends InheritedWidget {
  final ManaState state;

  const ManaScope({super.key, required this.state, required super.child});

  static ManaState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<ManaScope>();
    assert(result != null, 'No ManaScope found in context');
    return result!.state;
  }

  @override
  bool updateShouldNotify(ManaScope oldWidget) => state != oldWidget.state;
}
