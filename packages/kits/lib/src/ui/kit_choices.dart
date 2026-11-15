import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_widgets.dart';

import 'kit_icons.dart';
import 'kit_style.dart';

enum _ChoiceAppearance { tabs, segments }

const _choiceTextStyle = TextStyle(fontSize: 13, fontWeight: .w600);
const _tabTextStyle = TextStyle(fontSize: 12, height: 1.25, fontWeight: .w600);

Duration _tabDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 180);

// Reserve the same text width in both states, including at large text scales.
List<double> _choiceWidths(
  BuildContext context,
  List<String> labels, {
  TextStyle style = _choiceTextStyle,
  double padding = 28,
  double minWidth = 44,
}) => labels.map((label) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final width = math.max(minWidth, painter.width.ceilToDouble() + padding);
  painter.dispose();
  return width;
}).toList();

/// Compact iOS-style segmented tabs, with one shared rail and sliding thumb.
class KitTabs<T> extends StatelessWidget {
  const KitTabs({
    super.key,
    required this.values,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T)? label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(horizontal: 8, vertical: 4),
    child: _ChoiceStrip<T>(
      values: values,
      value: value,
      onChanged: onChanged,
      labels: [for (final item in values) label?.call(item) ?? '$item'],
      appearance: .tabs,
    ),
  );
}

/// A labelled form value: segments when they fit, a menu otherwise.
class KitChoiceField<T> extends StatelessWidget {
  const KitChoiceField({
    super.key,
    required this.fieldLabel,
    required this.values,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final String fieldLabel;
  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T)? label;

  @override
  Widget build(BuildContext context) {
    final labels = [for (final item in values) label?.call(item) ?? '$item'];
    return Padding(
      padding: const .all(8),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 4,
        children: [
          Text(
            fieldLabel,
            style: const TextStyle(fontSize: 12, color: KitStyle.muted),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final widths = _choiceWidths(context, labels);
              final needed = widths.fold(0.0, math.max) * values.length + 6;
              if (needed <= constraints.maxWidth) {
                return Semantics(
                  label: fieldLabel,
                  child: _ChoiceStrip<T>(
                    values: values,
                    value: value,
                    onChanged: onChanged,
                    labels: labels,
                    appearance: .segments,
                  ),
                );
              }
              return _ChoiceMenu<T>(
                fieldLabel: fieldLabel,
                values: values,
                value: value,
                labels: labels,
                onChanged: onChanged,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChoiceStrip<T> extends StatefulWidget {
  const _ChoiceStrip({
    required this.values,
    required this.value,
    required this.labels,
    required this.onChanged,
    required this.appearance,
  });

  final List<T> values;
  final T value;
  final List<String> labels;
  final ValueChanged<T> onChanged;
  final _ChoiceAppearance appearance;

  @override
  State<_ChoiceStrip<T>> createState() => _ChoiceStripState<T>();
}

class _ChoiceStripState<T> extends State<_ChoiceStrip<T>> {
  final _scroll = ScrollController();
  final _keys = <T, GlobalKey>{};
  final _focusNodes = <T, FocusNode>{};
  Object? _layout;

  KeyEventResult _navigate(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return .ignored;
    final rtl = Directionality.of(context) == .rtl;
    final next = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => index + (rtl ? -1 : 1),
      LogicalKeyboardKey.arrowLeft => index + (rtl ? 1 : -1),
      LogicalKeyboardKey.home => 0,
      LogicalKeyboardKey.end => widget.values.length - 1,
      _ => null,
    };
    if (next == null) return .ignored;
    final value = widget.values[next % widget.values.length];
    _focusNodes[value]!.requestFocus();
    if (value != widget.value) widget.onChanged(value);
    return .handled;
  }

  void _reveal(GlobalKey key) {
    final target = key.currentContext?.findRenderObject();
    if (!mounted || !_scroll.hasClients || target == null) return;
    // Only move this horizontal strip, never a surrounding form/header scroll.
    _scroll.position.ensureVisible(target, alignmentPolicy: .keepVisibleAtEnd);
    _scroll.position.ensureVisible(
      target,
      alignmentPolicy: .keepVisibleAtStart,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tabs = widget.appearance == .tabs;
      final widths = _choiceWidths(
        context,
        widget.labels,
        style: tabs ? _tabTextStyle : _choiceTextStyle,
        padding: tabs ? 16 : 28,
        minWidth: tabs ? 32 : 44,
      );
      final available = constraints.maxWidth - (tabs ? 4 : 6);
      final equalWidth =
          widths.isNotEmpty &&
          constraints.hasBoundedWidth &&
          widths.fold(0.0, math.max) * widths.length <= available;
      final totalWidth = widths.fold(0.0, (a, b) => a + b);
      final extra =
          tabs &&
              constraints.hasBoundedWidth &&
              totalWidth < available &&
              widths.isNotEmpty
          ? (available - totalWidth) / widths.length
          : 0.0;
      final itemWidths = [
        for (final width in widths)
          if (equalWidth) available / widths.length else width + extra,
      ];
      _keys.removeWhere((value, _) => !widget.values.contains(value));
      _focusNodes.removeWhere((value, node) {
        if (widget.values.contains(value)) return false;
        node.dispose();
        return true;
      });
      for (final value in widget.values) {
        _keys.putIfAbsent(value, GlobalKey.new);
        _focusNodes.putIfAbsent(value, FocusNode.new);
      }
      final layout = (
        constraints.maxWidth,
        Directionality.of(context),
        MediaQuery.textScalerOf(context),
        widget.labels.join('\u0000'),
        widget.values.indexOf(widget.value),
      );
      if (_layout != layout) {
        _layout = layout;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_keys[widget.value] case final key?) _reveal(key);
        });
      }
      final row = Semantics(
        role: tabs && widget.values.isNotEmpty ? .tabBar : .none,
        container: true,
        explicitChildNodes: true,
        child: Row(
          mainAxisSize: .min,
          children: [
            for (var index = 0; index < widget.values.length; index++)
              SizedBox(
                key: _keys[widget.values[index]],
                width: itemWidths[index],
                child: MergeSemantics(
                  child: Focus(
                    includeSemantics: false,
                    skipTraversal: true,
                    onKeyEvent: (_, event) => _navigate(index, event),
                    onFocusChange: (focused) {
                      if (focused) _reveal(_keys[widget.values[index]]!);
                    },
                    child: _ChoiceButton(
                      focusNode: _focusNodes[widget.values[index]]!,
                      label: widget.labels[index],
                      selected: widget.values[index] == widget.value,
                      appearance: widget.appearance,
                      separator:
                          tabs &&
                          index > 0 &&
                          widget.values[index] != widget.value &&
                          widget.values[index - 1] != widget.value,
                      onPressed: () {
                        if (widget.values[index] != widget.value) {
                          widget.onChanged(widget.values[index]);
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
      return DecoratedBox(
        key: tabs ? const ValueKey('kit-tabs-rail') : null,
        decoration: BoxDecoration(
          color: tabs ? const Color(0xFFEDEDF0) : KitStyle.subtle,
          borderRadius: .circular(tabs ? 7 : 8),
        ),
        child: Padding(
          padding: .all(tabs ? 2 : 3),
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: .horizontal,
            child: tabs
                ? _TabIndicatorTrack(
                    widths: itemWidths,
                    selectedIndex: widget.values.indexOf(widget.value),
                    child: row,
                  )
                : row,
          ),
        ),
      );
    },
  );
}

/// One rectangular thumb beneath the labels, not an individual pill per item.
/// It shares the labels' scroll coordinate space, including in RTL layouts.
class _TabIndicatorTrack extends StatelessWidget {
  const _TabIndicatorTrack({
    required this.widths,
    required this.selectedIndex,
    required this.child,
  });

  final List<double> widths;
  final int selectedIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (selectedIndex < 0 || selectedIndex >= widths.length) return child;
    final selectedWidth = widths[selectedIndex];
    final start = widths.take(selectedIndex).fold(0.0, (a, b) => a + b);
    return Stack(
      children: [
        AnimatedPositionedDirectional(
          duration: _tabDuration(context),
          curve: Curves.easeOutCubic,
          start: start,
          top: 0,
          bottom: 0,
          width: selectedWidth,
          child: const IgnorePointer(
            child: ExcludeSemantics(
              child: DecoratedBox(
                key: ValueKey('kit-tabs-indicator'),
                decoration: BoxDecoration(
                  color: KitStyle.surface,
                  borderRadius: .all(Radius.circular(5)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.appearance,
    required this.onPressed,
    required this.focusNode,
    required this.separator,
  });

  final bool separator;
  final FocusNode focusNode;
  final String label;
  final bool selected;
  final _ChoiceAppearance appearance;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tabs = appearance == .tabs;
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      textAlign: .center,
      style: (tabs ? _tabTextStyle : _choiceTextStyle).copyWith(
        color: tabs
            ? KitStyle.text
            : (selected ? KitStyle.accent : KitStyle.muted),
        fontWeight: selected ? .w600 : .w400,
      ),
    );
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      role: tabs ? .tab : null,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: ManaButton(
              focusNode: focusNode,
              onPressed: onPressed,
              constraints: BoxConstraints(
                minWidth: tabs ? 32 : 44,
                minHeight: tabs ? 28 : 44,
              ),
              padding: tabs
                  ? const .symmetric(horizontal: 8, vertical: 6)
                  : const .symmetric(vertical: 6),
              decoration: tabs
                  ? const BoxDecoration(borderRadius: .all(Radius.circular(5)))
                  : null,
              child: tabs
                  ? text
                  : Container(
                      width: double.infinity,
                      padding: const .symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? KitStyle.surface : null,
                        borderRadius: .circular(5),
                      ),
                      child: text,
                    ),
            ),
          ),
          if (separator)
            const PositionedDirectional(
              start: 0,
              top: 7,
              bottom: 7,
              width: 1,
              child: IgnorePointer(child: ColoredBox(color: Color(0xFFD1D1D6))),
            ),
        ],
      ),
    );
  }
}

class _ChoiceMenu<T> extends StatefulWidget {
  const _ChoiceMenu({
    required this.fieldLabel,
    required this.values,
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final String fieldLabel;
  final List<T> values;
  final T value;
  final List<String> labels;
  final ValueChanged<T> onChanged;

  @override
  State<_ChoiceMenu<T>> createState() => _ChoiceMenuState<T>();
}

class _ChoiceMenuState<T> extends State<_ChoiceMenu<T>> {
  final _controller = MenuController();
  final _anchorFocus = FocusNode();
  final _itemFocus = <T, FocusNode>{};

  @override
  void initState() {
    super.initState();
    _syncFocus();
  }

  @override
  void didUpdateWidget(_ChoiceMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocus();
  }

  void _syncFocus() {
    _itemFocus.removeWhere((value, node) {
      if (widget.values.contains(value)) return false;
      node.dispose();
      return true;
    });
    for (final value in widget.values) {
      _itemFocus.putIfAbsent(value, FocusNode.new);
    }
  }

  @override
  void dispose() {
    _anchorFocus.dispose();
    for (final node in _itemFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawMenuAnchor(
    controller: _controller,
    childFocusNode: _anchorFocus,
    consumeOutsideTaps: true,
    onOpen: () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.isOpen) return;
        final node = _itemFocus[widget.value] ?? _itemFocus.values.first;
        FocusTraversalPolicy.defaultTraversalRequestFocusCallback(node);
      });
    },
    builder: (context, controller, _) => Semantics(
      label: widget.fieldLabel,
      expanded: controller.isOpen,
      child: ManaButton(
        focusNode: _anchorFocus,
        onPressed: widget.values.isEmpty
            ? null
            : () => controller.isOpen ? controller.close() : controller.open(),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const .all(10),
        decoration: BoxDecoration(
          color: KitStyle.subtle,
          border: Border.all(color: KitStyle.border),
          borderRadius: .circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.labels.elementAtOrNull(
                      widget.values.indexOf(widget.value),
                    ) ??
                    '',
                overflow: .ellipsis,
                style: _choiceTextStyle.copyWith(color: KitStyle.text),
              ),
            ),
            const KitGlyph(.chevronDown, size: 16, color: KitStyle.muted),
          ],
        ),
      ),
    ),
    overlayBuilder: (context, info) => CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: info.anchorRect.topCenter,
        anchorBelow: info.anchorRect.bottomCenter,
      ),
      child: TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (_) => _controller.close(),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: widget.fieldLabel,
          role: .menu,
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
              SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
              SingleActivator(LogicalKeyboardKey.arrowUp):
                  PreviousFocusIntent(),
            },
            child: Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) {
                    _controller.close();
                    return null;
                  },
                ),
              },
              child: FocusScope(
                child: FocusTraversalGroup(
                  child: Container(
                    width: math.max(info.anchorRect.width, 200),
                    constraints: BoxConstraints(
                      maxHeight: info.overlaySize.height * .6,
                    ),
                    padding: const .all(4),
                    decoration: BoxDecoration(
                      color: KitStyle.surface,
                      border: Border.all(color: KitStyle.border),
                      borderRadius: .circular(8),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 8),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: .stretch,
                        mainAxisSize: .min,
                        children: [
                          for (
                            var index = 0;
                            index < widget.values.length;
                            index++
                          )
                            Semantics(
                              selected: widget.values[index] == widget.value,
                              inMutuallyExclusiveGroup: true,
                              child: ManaButton(
                                focusNode: _itemFocus[widget.values[index]],
                                onPressed: () {
                                  _controller.close();
                                  if (widget.values[index] != widget.value) {
                                    widget.onChanged(widget.values[index]);
                                  }
                                },
                                child: Align(
                                  alignment: .centerStart,
                                  child: Text(
                                    widget.labels[index],
                                    style: _choiceTextStyle.copyWith(
                                      color:
                                          widget.values[index] == widget.value
                                          ? KitStyle.accent
                                          : KitStyle.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
