import 'package:flutter/widgets.dart';

import 'kit_style.dart';
import 'kit_button.dart';

final kitSelectionControls = _KitSelectionControls();

class _KitSelectionControls extends EmptyTextSelectionControls
    with TextSelectionHandleControls {
  static const _handleSize = 18.0;
  static const _touchTargetSize = 48.0;
  static const _inset = (_touchTargetSize - _handleSize) / 2;

  @override
  Size getHandleSize(double textLineHeight) =>
      const Size.square(_touchTargetSize);
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      switch (type) {
        .left => const Offset(_inset + _handleSize, _inset),
        .right => const Offset(_inset, _inset),
        .collapsed => const Offset(_touchTargetSize / 2, _inset),
      };
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => SizedBox.square(
    // Match the overlay's advertised size under loose constraints. Make the
    // entire target hit-testable, including the space around the visual handle,
    // so a near-edge grab stays inside the selection's TapRegion.
    dimension: _touchTargetSize,
    child: GestureDetector(
      behavior: .opaque,
      onTap: onTap,
      child: Center(
        child: SizedBox.square(
          dimension: _handleSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: KitStyle.accent,
              borderRadius: BorderRadius.only(
                topLeft: type == .right
                    ? .zero
                    : const .circular(_handleSize / 2),
                topRight: type == .left
                    ? .zero
                    : const .circular(_handleSize / 2),
                bottomLeft: const .circular(_handleSize / 2),
                bottomRight: const .circular(_handleSize / 2),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class KitSelection extends StatefulWidget {
  const KitSelection({super.key, required this.child});
  final Widget child;
  @override
  State<KitSelection> createState() => _KitSelectionState();
}

class _KitSelectionState extends State<KitSelection> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectableRegion(
    focusNode: _focus,
    selectionControls: kitSelectionControls,
    contextMenuBuilder: (context, state) => KitSelectionMenu(
      anchors: state.contextMenuAnchors,
      items: state.contextMenuButtonItems,
    ),
    child: widget.child,
  );
}

class KitSelectionMenu extends StatelessWidget {
  const KitSelectionMenu({
    super.key,
    required this.anchors,
    required this.items,
  });
  final TextSelectionToolbarAnchors anchors;
  final List<ContextMenuButtonItem> items;
  @override
  Widget build(BuildContext context) {
    final locale = WidgetsLocalizations.of(context);
    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KitStyle.surface,
          border: Border.all(color: KitStyle.border),
          borderRadius: .circular(6),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
        ),
        child: Wrap(
          children: [
            for (final item in items)
              KitButton(
                label:
                    item.label ??
                    switch (item.type) {
                      .copy => locale.copyButtonLabel,
                      .cut => locale.cutButtonLabel,
                      .paste => locale.pasteButtonLabel,
                      .selectAll => locale.selectAllButtonLabel,
                      _ => item.type.name,
                    },
                onPressed: item.onPressed,
              ),
          ],
        ),
      ),
    );
  }
}
