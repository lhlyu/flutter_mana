import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana/flutter_mana_diagnostics.dart';

import '../../../diagnostics/debug_session.dart';
import '../../../ui/kit_ui.dart';
import '../inspector_snapshot.dart';

enum InspectorTab { layout, properties, diagnostics }

class WidgetInfoInspector extends StatefulWidget {
  const WidgetInfoInspector({super.key, required this.name});
  final String name;
  @override
  State<WidgetInfoInspector> createState() => _WidgetInfoInspectorState();
}

class _WidgetInfoInspectorState extends State<WidgetInfoInspector> {
  final _session = DebugSession();
  final _paintKey = GlobalKey();
  final _propertyQuery = TextEditingController();
  final _scroll = ScrollController();
  final _headerScroll = ScrollController();
  List<Element> _candidates = const [];
  Element? _selected;
  Widget? _selectedWidget;
  InspectorSnapshot? _snapshot;
  InspectorTab _tab = .layout;
  bool _picking = true;
  bool _collapsed = false;
  bool _choosing = false;
  bool _stale = false;
  bool _layout = DebugSession.read(.layout) as bool;
  bool _showSize = true;
  bool _showFramework = false;
  Object? _settingsError;
  late ManaPreferences _preferences;

  @override
  void initState() {
    super.initState();
    // Observe existing app frames without driving a permanent animation loop.
    WidgetsBinding.instance.addPostFrameCallback(_checkSelection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preferences = ManaScope.read(context).preferences;
    _showSize = _preferences.read('mana_inspector_show_size') != false;
    _showFramework = _preferences.read('mana_inspector_show_framework') == true;
  }

  @override
  void dispose() {
    _propertyQuery.dispose();
    _scroll.dispose();
    _headerScroll.dispose();
    _session.dispose();
    super.dispose();
  }

  Element? get _root =>
      ManaScope.read(context).rootKey.currentContext as Element?;

  bool _valid(Element element) {
    final root = _root;
    if (root == null || !inspectorElementActive(element)) return false;
    return !identical(element, root) && inspectorWithinRoot(element, root);
  }

  List<Element> get _visibleCandidates => [
    for (final element in _candidates)
      if (_valid(element) &&
          (_showFramework || !inspectorFrameworkElement(element)))
        element,
  ];

  List<Element> get _ancestors {
    final root = _root;
    final selected = _selected;
    if (root == null || selected == null || !_valid(selected)) return const [];
    return [
      for (final element in inspectorAncestors(selected, root))
        if (_showFramework || !inspectorFrameworkElement(element)) element,
    ];
  }

  void _select(Element element) {
    final root = _root?.findRenderObject();
    if (!_valid(element) || root == null) return;
    _selected = element;
    _selectedWidget = element.widget;
    _snapshot = InspectorSnapshot.capture(element, root);
    _stale = false;
    _choosing = false;
  }

  void _inspect(TapDownDetails details) {
    if (!_picking) return;
    final root = _root;
    if (root == null) return;
    final elements = <Element>[];
    for (final hit in HitTestUtils.hitTest(
      details.globalPosition,
      rootKey: ManaScope.read(context).rootKey,
    )) {
      final creator = hit.debugCreator;
      if (creator is! DebugCreator) continue;
      final element = creator.element;
      if (!_valid(element)) continue;
      for (final candidate in [element, ...inspectorAncestors(element, root)]) {
        if (!elements.contains(candidate)) elements.add(candidate);
      }
    }
    setState(() {
      _candidates = elements;
      _selected = null;
      _snapshot = null;
      _stale = false;
      _choosing = false;
      final candidates = _visibleCandidates;
      if (candidates.isNotEmpty) _select(candidates.first);
    });
  }

  void _checkSelection(Duration _) {
    if (!mounted) return;
    final selected = _selected;
    if (TickerMode.valuesOf(context).enabled && selected != null) {
      if (!_valid(selected)) {
        if (!_stale) setState(() => _stale = true);
      } else {
        final root = _root?.findRenderObject();
        if (root != null) {
          final geometry = inspectorGeometry(selected, root);
          if (_stale || !identical(_selectedWidget, selected.widget)) {
            setState(() => _select(selected));
          } else if (geometry != _snapshot?.geometry) {
            setState(() => _snapshot = _snapshot?.withGeometry(geometry));
          }
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback(_checkSelection);
  }

  Future<void> _saveSetting(String key, bool value) async {
    setState(() => _settingsError = null);
    try {
      await _preferences.write(key, value);
    } catch (error) {
      if (mounted) setState(() => _settingsError = error);
    }
  }

  Widget _modeBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                KitButton(
                  label: kitText(context, 'inspector.pick'),
                  icon: .eye,
                  selected: _picking,
                  onPressed: () => setState(() => _picking = true),
                ),
                KitButton(
                  label: kitText(context, 'inspector.interact'),
                  selected: !_picking,
                  onPressed: () => setState(() => _picking = false),
                ),
              ],
            ),
          ),
        ),
        KitButton(
          label: kitText(
            context,
            _collapsed ? 'inspector.expand' : 'inspector.collapse',
          ),
          icon: _collapsed ? .top : .bottom,
          iconOnly: true,
          onPressed: () {
            final runtime = ManaScope.read(context);
            if (!_collapsed && runtime.state.windowMode == .fullscreen) {
              runtime.toggleFullscreen();
            }
            setState(() => _collapsed = !_collapsed);
          },
        ),
      ],
    ),
  );

  Widget _selectionHeader(BuildContext context) {
    final snapshot = _snapshot;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              snapshot?.name ?? kitText(context, 'inspector.no_selection'),
              key: const ValueKey('inspector-selection-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (snapshot != null && !_collapsed) KitCopyButton(snapshot.summary),
        ],
      ),
    );
  }

  Widget _parentPath(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    reverse: true,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        for (final parent in _ancestors.reversed) ...[
          KitButton(
            label: parent.widget.toStringShort(),
            onPressed: () => setState(() => _select(parent)),
          ),
          const Text('›', style: TextStyle(color: KitStyle.muted)),
        ],
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(_snapshot!.name, style: const TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );

  Widget _navigation(BuildContext context) {
    final parents = _ancestors;
    final candidates = _visibleCandidates;
    final index = candidates.indexOf(_selected!);
    return KitToolbar(
      children: [
        KitButton(
          label: kitText(context, 'inspector.select_parent'),
          icon: .top,
          onPressed: parents.isEmpty
              ? null
              : () => setState(() => _select(parents.first)),
        ),
        KitButton(
          label:
              '${kitText(context, 'inspector.candidates')} '
              '${index < 0 ? '—' : index + 1}/${candidates.length}',
          icon: .filter,
          selected: _choosing,
          onPressed: candidates.isEmpty
              ? null
              : () => setState(() => _choosing = !_choosing),
        ),
        KitButton(
          label: kitText(context, 'common.refresh'),
          icon: .refresh,
          iconOnly: true,
          onPressed: () => setState(() => _select(_selected!)),
        ),
      ],
    );
  }

  Widget _controls(BuildContext context, {required bool valid}) => ColoredBox(
    color: KitStyle.surface,
    child: Column(
      key: const ValueKey('inspector-controls'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _modeBar(context),
        _selectionHeader(context),
        if (valid) ...[
          if (_ancestors.isNotEmpty) _parentPath(context),
          _navigation(context),
          KitTabs<InspectorTab>(
            values: InspectorTab.values,
            value: _tab,
            label: (tab) => kitText(context, 'inspector.${tab.name}'),
            onChanged: (tab) {
              setState(() {
                _tab = tab;
                _choosing = false;
              });
              if (_scroll.hasClients) _scroll.jumpTo(0);
            },
          ),
        ],
        const KitDivider(),
      ],
    ),
  );

  List<Widget> _detailSlivers(BuildContext context) {
    final snapshot = _snapshot!;
    final geometry = snapshot.geometry;
    switch (_tab) {
      case .layout:
        return [
          SliverToBoxAdapter(
            child: KitDataTable({
              'Widget': snapshot.name,
              'Key': snapshot.keyLabel,
              kitText(context, 'inspector.size'): geometry == null
                  ? null
                  : inspectorSize(geometry.size),
              kitText(context, 'inspector.position'): geometry == null
                  ? null
                  : 'x: ${inspectorNumber(geometry.bounds.left)}  '
                        'y: ${inspectorNumber(geometry.bounds.top)}',
              kitText(context, 'inspector.constraints'): geometry?.constraints,
              'RenderObject': geometry?.renderType,
              kitText(context, 'inspector.source'): snapshot.source,
            }),
          ),
          if (geometry == null)
            SliverToBoxAdapter(
              child: KitMessage(kitText(context, 'inspector.no_geometry')),
            ),
        ];
      case .properties:
        final query = _propertyQuery.text.trim().toLowerCase();
        final properties = snapshot.properties
            .where(
              (property) => '${property.name} ${property.value}'
                  .toLowerCase()
                  .contains(query),
            )
            .toList();
        return [
          SliverToBoxAdapter(
            child: KitField(
              controller: _propertyQuery,
              hintText: kitText(context, 'common.search'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (properties.isEmpty)
            SliverToBoxAdapter(
              child: KitMessage(kitText(context, 'common.empty')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) => KitInfoField(
                  label: properties[index].name,
                  value: properties[index].value,
                ),
              ),
            ),
        ];
      case .diagnostics:
        return [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: KitCopyButton(snapshot.diagnostics),
                ),
                if (snapshot.diagnosticsError case final error?)
                  KitMessage(error, error: true),
                KitCode(snapshot.diagnostics),
              ],
            ),
          ),
        ];
    }
  }

  Widget _panelContent(
    BuildContext context, {
    required bool valid,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
      final detailsSpace = math.min(180 * scale, constraints.maxHeight * .45);
      // Sibling scroll surfaces: dragging details can never move the controls.
      // Short windows reserve room for details and let only the header's own
      // gestures reveal overflowing controls.
      final header = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: _collapsed
              ? constraints.maxHeight
              : math.max(0, constraints.maxHeight - detailsSpace),
        ),
        child: SingleChildScrollView(
          key: const ValueKey('inspector-header-scroll'),
          controller: _headerScroll,
          primary: false,
          physics: const ClampingScrollPhysics(),
          child: _controls(context, valid: valid && !_collapsed),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (!_collapsed)
            Expanded(
              child: CustomScrollView(
                key: const ValueKey('inspector-scroll'),
                controller: _scroll,
                primary: false,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (_stale)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: KitMessage(kitText(context, 'inspector.stale')),
                    )
                  else if (!valid)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: KitMessage(
                        kitText(
                          context,
                          _picking
                              ? 'inspector.pick_hint'
                              : 'inspector.interact_hint',
                        ),
                      ),
                    )
                  else if (_choosing)
                    SliverList.list(
                      key: const ValueKey('inspector-candidates'),
                      children: [
                        for (final candidate in _visibleCandidates)
                          KitButton(
                            label: candidate.widget.toStringShort(),
                            selected: identical(candidate, _selected),
                            onPressed: () => setState(() => _select(candidate)),
                          ),
                      ],
                    )
                  else
                    ..._detailSlivers(context),
                ],
              ),
            ),
        ],
      );
    },
  );

  Widget _settings(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          KitToggle(
            label: kitText(context, 'visual_helper.layout_bounds'),
            value: _layout,
            onChanged: (value) => setState(() {
              _layout = value;
              _session.set(.layout, value);
            }),
          ),
          KitToggle(
            label: kitText(context, 'inspector.show_size'),
            value: _showSize,
            onChanged: (value) async {
              setState(() => _showSize = value);
              await _saveSetting('mana_inspector_show_size', value);
            },
          ),
          KitToggle(
            label: kitText(context, 'inspector.show_framework'),
            value: _showFramework,
            onChanged: (value) async {
              setState(() {
                _showFramework = value;
                if (!value &&
                    _selected != null &&
                    _valid(_selected!) &&
                    inspectorFrameworkElement(_selected!)) {
                  final candidates = _visibleCandidates;
                  if (candidates.isNotEmpty) _select(candidates.first);
                }
              });
              await _saveSetting('mana_inspector_show_framework', value);
            },
          ),
          if (_settingsError case final error?)
            KitMessage('$error', error: true),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final mobile = media.size.width < 600;
    final scale = media.textScaler.scale(13) / 13;
    final expandedHeight = mobile
        ? media.size.height * .78
        : math.min(640.0, media.size.height * .85);
    final height = _collapsed
        ? math.min(expandedHeight, 40 + 88 * scale)
        : expandedHeight;
    final selected = _selected;
    final valid = selected != null && !_stale && _valid(selected);
    return KitWindow(
      key: ValueKey(mobile),
      name: widget.name,
      initialWidth: mobile ? double.infinity : 420,
      initialHeight: expandedHeight,
      height: height,
      position: mobile ? .bottom : .normal,
      drag: !mobile,
      barrier: IgnorePointer(
        ignoring: !_picking,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _inspect,
          child: SizedBox.expand(
            child: IgnorePointer(
              child: CustomPaint(
                key: _paintKey,
                painter: _HighlightPainter(
                  valid ? inspectorRenderObject(selected) : null,
                  _paintKey,
                  showSize: _showSize,
                  direction: Directionality.of(context),
                  textScaler: media.textScaler,
                ),
              ),
            ),
          ),
        ),
      ),
      setting: _settings(context),
      content: _panelContent(context, valid: valid),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  const _HighlightPainter(
    this.selected,
    this.key, {
    required this.showSize,
    required this.direction,
    required this.textScaler,
  });
  final RenderObject? selected;
  final GlobalKey key;
  final bool showSize;
  final TextDirection direction;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final target = selected;
    final box = key.currentContext?.findRenderObject();
    if (target == null ||
        !target.attached ||
        box == null ||
        !box.attached ||
        (target is RenderBox && !target.hasSize)) {
      return;
    }
    final rect = MatrixUtils.transformRect(
      target.getTransformTo(box),
      target.paintBounds,
    );
    if (!rect.isFinite) return;
    canvas.drawRect(
      rect,
      Paint()..color = KitStyle.accent.withValues(alpha: .12),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = KitStyle.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (!showSize || size.width < 32 || size.height < 24) return;
    final painter = TextPainter(
      text: TextSpan(
        text: inspectorSize(
          target is RenderBox ? target.size : target.paintBounds.size,
        ),
        style: const TextStyle(
          fontSize: 12,
          color: KitStyle.surface,
          height: 1.3,
        ),
      ),
      textDirection: direction,
      textScaler: textScaler,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, size.width - 24));
    final width = painter.width + 12;
    final height = painter.height + 8;
    final left = rect.left.clamp(4.0, math.max(4.0, size.width - width - 4));
    final top =
        (rect.top - height - 4 >= 4 ? rect.top - height - 4 : rect.bottom + 4)
            .clamp(4.0, math.max(4.0, size.height - height - 4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left.toDouble(), top.toDouble(), width, height),
        const Radius.circular(4),
      ),
      Paint()..color = KitStyle.accent,
    );
    painter.paint(canvas, Offset(left + 6, top + 4));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => true;
}
