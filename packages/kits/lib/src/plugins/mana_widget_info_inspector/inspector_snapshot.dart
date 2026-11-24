import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

bool inspectorElementActive(Element element) =>
    element.mounted && element.debugIsActive;

/// Creation sites distinguish framework implementation nodes from widgets
/// explicitly constructed by application code, including Flutter widgets.
bool inspectorFrameworkElement(Element element) {
  if (!inspectorElementActive(element)) return true;
  final location = developer.CreationLocation.of(element.widget);
  if (location == null) {
    return element.widget.runtimeType.toString().startsWith('_');
  }
  final file = location.file;
  return file.startsWith('dart:') ||
      file.startsWith('package:flutter/') ||
      file.contains('/packages/flutter/lib/');
}

bool inspectorWithinRoot(Element element, Element root) {
  if (!inspectorElementActive(element)) return false;
  var inside = identical(element, root);
  element.visitAncestorElements((ancestor) {
    if (identical(ancestor, root)) inside = true;
    return !inside;
  });
  return inside;
}

List<Element> inspectorAncestors(Element element, Element root) {
  if (!inspectorElementActive(element) || identical(element, root)) {
    return const [];
  }
  final result = <Element>[];
  element.visitAncestorElements((ancestor) {
    if (identical(ancestor, root)) return false;
    if (inspectorElementActive(ancestor)) result.add(ancestor);
    return true;
  });
  // A removed or reparented selection must not expose another host's tree.
  return inspectorWithinRoot(element, root) ? result : const [];
}

typedef InspectorGeometry = ({
  Rect bounds,
  Size size,
  String constraints,
  String renderType,
});

RenderObject? inspectorRenderObject(Element element) {
  if (!inspectorElementActive(element)) return null;
  final object = element.findRenderObject();
  return object != null && object.attached ? object : null;
}

InspectorGeometry? inspectorGeometry(Element element, RenderObject root) {
  final object = inspectorRenderObject(element);
  if (object == null ||
      !root.attached ||
      (object is RenderBox && !object.hasSize)) {
    return null;
  }
  final bounds = MatrixUtils.transformRect(
    object.getTransformTo(root),
    object.paintBounds,
  );
  if (!bounds.isFinite) return null;
  return (
    bounds: bounds,
    size: object is RenderBox ? object.size : object.paintBounds.size,
    constraints: object is RenderBox
        ? object.constraints.toString()
        : object
              .toDiagnosticsNode()
              .getProperties()
              .where((property) => property.name == 'constraints')
              .map((property) => property.toDescription())
              .join(),
    renderType: object.runtimeType.toString(),
  );
}

/// Only live navigation keeps Elements; diagnostic text is captured on demand.
@immutable
class InspectorSnapshot {
  const InspectorSnapshot({
    required this.name,
    required this.keyLabel,
    required this.source,
    required this.properties,
    required this.diagnostics,
    required this.geometry,
    this.diagnosticsError,
  });

  final String name;
  final String? keyLabel;
  final String? source;
  final List<({String name, String value})> properties;
  final String diagnostics;
  final InspectorGeometry? geometry;
  final String? diagnosticsError;

  factory InspectorSnapshot.capture(Element element, RenderObject root) {
    final widget = element.widget;
    final properties = <({String name, String value})>[];
    String? error;
    var raw = '';
    try {
      final node = widget.toDiagnosticsNode();
      for (final property in node.getProperties()) {
        if (property.isFiltered(DiagnosticLevel.info)) continue;
        properties.add((
          name: property.name ?? property.toString(),
          value: property.toDescription(),
        ));
      }
      raw = 'Widget\n${node.toStringDeep()}';
    } catch (exception) {
      error = '$exception';
    }
    final render = inspectorRenderObject(element);
    if (render != null) {
      try {
        raw += '\nRenderObject\n${render.toStringShort()}\n';
        for (final property in render.toDiagnosticsNode().getProperties()) {
          if (!property.isFiltered(DiagnosticLevel.info)) {
            raw += '${property.toString()}\n';
          }
        }
      } catch (exception) {
        error = '$exception';
      }
    }
    return InspectorSnapshot(
      name: widget.toStringShort(),
      keyLabel: widget.key?.toString(),
      source: developer.CreationLocation.of(widget)?.toString(),
      properties: List.unmodifiable(properties),
      diagnostics: raw,
      geometry: inspectorGeometry(element, root),
      diagnosticsError: error,
    );
  }

  InspectorSnapshot withGeometry(InspectorGeometry? value) => InspectorSnapshot(
    name: name,
    keyLabel: keyLabel,
    source: source,
    properties: properties,
    diagnostics: diagnostics,
    geometry: value,
    diagnosticsError: diagnosticsError,
  );

  String get summary => [
    name,
    if (keyLabel != null) 'Key: $keyLabel',
    if (geometry case final layout?) ...[
      'Size: ${inspectorSize(layout.size)}',
      'Position (host): ${inspectorNumber(layout.bounds.left)}, '
          '${inspectorNumber(layout.bounds.top)}',
      'Constraints: ${layout.constraints}',
    ],
    if (source != null) 'Source: $source',
  ].join('\n');
}

String inspectorNumber(double value) => value.isInfinite
    ? '∞'
    : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

String inspectorSize(Size value) =>
    '${inspectorNumber(value.width)} × ${inspectorNumber(value.height)}';
