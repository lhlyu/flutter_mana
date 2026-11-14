import 'package:flutter/widgets.dart';

import 'mana_controller.dart';

/// Navigator 1 integration: consume debug back actions before popping host routes.
/// Router hosts should instead pass their BackButtonDispatcher to ManaWidget.builder.
final class ManaNavigatorObserver extends NavigatorObserver {
  final ManaController controller;
  ModalRoute<dynamic>? _route;
  ModalRoute<dynamic>? _entryRoute;
  LocalHistoryEntry? _entry;
  bool _scheduled = false;
  bool _closed = false;
  bool _removing = false;

  ManaNavigatorObserver(this.controller) {
    controller.addListener(_schedule);
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _route = topRoute is ModalRoute ? topRoute : null;
    _schedule();
  }

  void _schedule() {
    if (_closed || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_closed) _sync();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _removeEntry() {
    _removing = true;
    _entry?.remove();
    _entry = null;
    _entryRoute = null;
    _removing = false;
  }

  void _sync() {
    if (_entryRoute != _route ||
        !controller.canHandleBack ||
        controller.isClosed) {
      _removeEntry();
    }
    final route = _route;
    if (route == null ||
        _entry != null ||
        controller.isClosed ||
        !controller.canHandleBack) {
      return;
    }
    _entryRoute = route;
    _entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () {
        if (_removing) return;
        _entry = null;
        _entryRoute = null;
        controller.handleBack();
        _schedule();
      },
    );
    route.addLocalHistoryEntry(_entry!);
  }

  void dispose() {
    if (_closed) return;
    _closed = true;
    controller.removeListener(_schedule);
    _removeEntry();
  }
}
