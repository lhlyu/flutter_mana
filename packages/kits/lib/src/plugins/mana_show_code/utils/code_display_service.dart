import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';
import 'package:vm_service/vm_service.dart' as vm;

class PageSource {
  const PageSource({
    required this.widgetName,
    required this.uri,
    required this.source,
  });
  final String widgetName;
  final String uri;
  final String source;
}

class CodeDisplayService {
  CodeDisplayService({
    VmInspector? inspector,
    String? Function(Object)? objectId,
  }) : inspector = inspector ?? VmInspector(),
       _objectId = objectId ?? developer.Service.getObjectId;
  final VmInspector inspector;
  final String? Function(Object) _objectId;

  Future<PageSource?> currentPage(BuildContext? root) async {
    if (root is! Element || !root.mounted) return null;
    final candidates = _pageWidgets(root);
    final classes = <Type, vm.Class?>{};
    for (final widget in candidates) {
      final type = widget.runtimeType;
      if (!classes.containsKey(type)) {
        final id = _objectId(widget);
        final instance = id == null ? null : await inspector.getObject(id);
        final classId = instance is vm.Instance ? instance.classRef?.id : null;
        final object = classId == null
            ? null
            : await inspector.getObject(classId);
        classes[type] = object is vm.Class ? object : null;
      }
      final klass = classes[type];
      final script = klass?.location?.script;
      final uri = script?.uri;
      if (script?.id == null || uri == null || !_isApplicationSource(uri)) {
        continue;
      }
      final object = await inspector.getObject(script!.id!);
      if (object is! vm.Script || object.source == null) {
        throw StateError('Source is unavailable: $uri');
      }
      return PageSource(
        widgetName: klass!.name ?? type.toString(),
        uri: uri,
        source: object.source!,
      );
    }
    return null;
  }

  bool _isApplicationSource(String uri) =>
      !uri.startsWith('dart:') &&
      !uri.startsWith('package:flutter/') &&
      !uri.startsWith('package:material_ui/') &&
      !uri.startsWith('package:cupertino_ui/') &&
      !uri.startsWith('package:flutter_mana/') &&
      !uri.startsWith('package:flutter_mana_kits/') &&
      !uri.contains('/packages/flutter/lib/');

  Future<void> close() => inspector.disconnect();
}

/// Read routes without adding dependencies to inspected elements.
class _RouteLookup implements BuildContext {
  _RouteLookup(this.context);
  final BuildContext context;

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) => context.getInheritedWidgetOfExactType<T>();

  @override
  InheritedElement?
  getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() =>
      context.getElementForInheritedWidgetOfExactType<T>();

  @override
  InheritedWidget dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) => ancestor.widget as InheritedWidget;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Route lookup only supports inherited reads.');
}

/// Prefer the innermost visible host route.
List<Widget> _pageWidgets(Element root) {
  final candidates = <({Widget widget, int depth})>[];
  var hasRoute = false;
  void visit(Element element, ModalRoute<dynamic>? parentRoute, int depth) {
    final widget = element.widget;
    if (widget is Offstage && widget.offstage) return;
    final route = ModalRoute.of(_RouteLookup(element));
    if (route != null) {
      hasRoute = true;
      if (!route.isCurrent) return;
    }
    final routeDepth = depth + (route != null && route != parentRoute ? 1 : 0);
    if (widget is StatelessWidget || widget is StatefulWidget) {
      candidates.add((widget: widget, depth: routeDepth));
    }
    if (widget is IndexedStack) {
      final index = widget.index;
      if (index == null) return;
      // IndexedStack retains inactive children without Offstage.
      final selected = widget.children[index];
      void findSelected(Element child) {
        if (identical(child.widget, selected)) {
          visit(child, route, routeDepth);
        } else if (!widget.children.any(
          (item) => identical(item, child.widget),
        )) {
          child.visitChildren(findSelected);
        }
      }

      element.visitChildren(findSelected);
      return;
    }
    element.visitChildren((child) => visit(child, route, routeDepth));
  }

  visit(root, null, 0);
  final depths = candidates.map((item) => item.depth).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  return [
    for (final depth in depths)
      if (!hasRoute || depth > 0)
        for (final item in candidates)
          if (item.depth == depth) item.widget,
  ];
}
