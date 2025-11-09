import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'widget_info_inspector_barrier.dart';
import 'widget_info_inspector_content.dart';

class WidgetInfoInspector extends StatefulWidget {
  final String name;

  const WidgetInfoInspector({super.key, required this.name});

  @override
  State<WidgetInfoInspector> createState() => _WidgetInfoInspectorState();
}

class _WidgetInfoInspectorState extends State<WidgetInfoInspector>
    with WidgetsBindingObserver {
  _WidgetInfoInspectorState()
    : selection = WidgetInspectorService.instance.selection;

  final InspectorSelection selection;

  /// 强制整个渲染树所有节点调用 markNeedsPaint()
  void markWholeRenderTreeNeedsPaint() {
    late RenderObjectVisitor visitor;

    visitor = (RenderObject child) {
      child.markNeedsPaint();
      child.visitChildren(visitor);
    };

    for (final renderView in RendererBinding.instance.renderViews) {
      renderView.visitChildren(visitor);
    }
  }

  void _inspectAt(Offset? position) {
    if (position == null) return;

    final List<RenderObject> renderObjects = HitTestUtils.hitTest(position);

    setState(() {
      selection.candidates = renderObjects;

      markWholeRenderTreeNeedsPaint();
    });
  }

  void _handleTapDown(TapDownDetails details) {
    _inspectAt(details.globalPosition);
  }

  @override
  void initState() {
    super.initState();
    selection.clear();
  }

  @override
  void dispose() {
    debugPaintSizeEnabled = false;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      markWholeRenderTreeNeedsPaint();
    });
    super.dispose();
  }

  void _showAllSize() async {
    debugPaintSizeEnabled = !debugPaintSizeEnabled;
    markWholeRenderTreeNeedsPaint();
  }

  @override
  Widget build(BuildContext context) {
    return ManaFloatingWindow(
      name: widget.name,
      initialWidth: 300,
      initialHeight: 100,
      barrier: WidgetInfoInspectorBarrier(
        selection: selection,
        onTapDown: _handleTapDown,
      ),
      content: WidgetInfoInspectorContent(
        selection: selection,
        onChanged: (value) {
          selection.clear();
          _showAllSize();
        },
      ),
    );
  }
}
