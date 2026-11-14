import 'package:flutter/widgets.dart';

import 'kit_style.dart';
import 'kit_button.dart';

final kitSelectionControls = _KitSelectionControls();

class _KitSelectionControls extends EmptyTextSelectionControls
    with TextSelectionHandleControls {
  @override
  Size getHandleSize(double textLineHeight) => const Size(18, 18);
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      const Offset(9, 0);
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => GestureDetector(
    onTap: onTap,
    child: const DecoratedBox(
      decoration: BoxDecoration(color: KitStyle.accent, shape: .circle),
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
