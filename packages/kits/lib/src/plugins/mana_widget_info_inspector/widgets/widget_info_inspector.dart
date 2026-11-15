import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';

import '../../../diagnostics/debug_session.dart';
import '../../../ui/kit_ui.dart';
import 'widget_info_inspector_detail.dart';

class WidgetInfoInspector extends StatefulWidget {
  const WidgetInfoInspector({super.key, required this.name});
  final String name;
  @override
  State<WidgetInfoInspector> createState() => _WidgetInfoInspectorState();
}

class _WidgetInfoInspectorState extends State<WidgetInfoInspector> {
  final _session = DebugSession();
  final _paintKey = GlobalKey();
  RenderObject? _selected;
  bool _details = false;
  bool _layout = DebugSession.read(.layout) as bool;
  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _inspect(TapDownDetails details) {
    final hits = HitTestUtils.hitTest(
      details.globalPosition,
      rootKey: ManaScope.read(context).rootKey,
    );
    setState(() {
      _selected = hits.firstOrNull;
      _details = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final creator = _selected?.debugCreator;
    final element = creator is DebugCreator && creator.element.mounted
        ? creator.element
        : null;
    return KitWindow(
      name: widget.name,
      initialWidth: 360,
      initialHeight: 340,
      barrier: GestureDetector(
        behavior: .opaque,
        onTapDown: _inspect,
        child: SizedBox.expand(
          child: IgnorePointer(
            child: CustomPaint(
              key: _paintKey,
              painter: _HighlightPainter(_selected, _paintKey),
            ),
          ),
        ),
      ),
      content: _details && element != null
          ? InfoPage(
              elements: element.debugGetDiagnosticChain(),
              onClose: () => setState(() => _details = false),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  KitToggle(
                    label: kitText(context, 'visual_helper.layout_bounds'),
                    value: _layout,
                    onChanged: (value) => setState(() {
                      _layout = value;
                      _session.set(.layout, value);
                    }),
                  ),
                  KitDataTable({
                    'Widget': element?.widget.toStringShort(),
                    'Bounds': _selected?.paintBounds,
                  }),
                  KitButton(
                    label: kitText(context, 'common.details'),
                    icon: .eye,
                    onPressed: element == null
                        ? null
                        : () => setState(() => _details = true),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  const _HighlightPainter(this.selected, this.key);
  final RenderObject? selected;
  final GlobalKey key;
  @override
  void paint(Canvas canvas, Size size) {
    final target = selected;
    final box = key.currentContext?.findRenderObject();
    if (target == null || !target.attached || box == null || !box.attached) {
      return;
    }
    final rect = MatrixUtils.transformRect(
      target.getTransformTo(box),
      target.paintBounds,
    );
    if (!rect.isFinite) return;
    canvas.drawRect(
      rect,
      Paint()..color = KitStyle.accent.withValues(alpha: .15),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = KitStyle.accent
        ..style = .stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => true;
}
