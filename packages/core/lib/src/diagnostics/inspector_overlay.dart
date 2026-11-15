import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

abstract final class _InspectorConstants {
  static const int maxTooltipLines = 10;

  static const double screenMargin = 10.0;

  static const double tooltipPadding = 8.0;

  static const double offsetFromWidget = 9.0;

  static const double tooltipFontSize = 12.0;

  static const double strokeWidth = 1.0;

  static const Color tooltipBackground = Color.fromARGB(230, 60, 60, 60);

  static const Color tooltipTextColor = Color(0xFFFFFFFF);

  static const Color selectionFill = Color.fromARGB(128, 128, 128, 255);

  static const Color selectionBorder = Color.fromARGB(128, 64, 64, 128);
}

/// Highlights the inspector selection and optionally shows bounds and details.
class InspectorOverlay extends LeafRenderObjectWidget {
  const InspectorOverlay({
    super.key,
    required this.selection,
    this.needEdges = true,
    this.needDescription = true,
  });

  final InspectorSelection selection;
  final bool needEdges;
  final bool needDescription;

  @override
  RenderInspectorOverlay createRenderObject(BuildContext context) =>
      RenderInspectorOverlay(
        selection: selection,
        needEdges: needEdges,
        needDescription: needDescription,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderInspectorOverlay renderObject,
  ) {
    renderObject
      ..selection = selection
      ..needEdges = needEdges
      ..needDescription = needDescription;
  }
}

class RenderInspectorOverlay extends RenderBox {
  RenderInspectorOverlay({
    required this._selection,
    required this._needEdges,
    required this._needDescription,
  });

  bool _needEdges;

  bool get needEdges => _needEdges;

  set needEdges(bool value) {
    if (value != _needEdges) {
      _needEdges = value;
      markNeedsPaint();
    }
  }

  bool _needDescription;

  bool get needDescription => _needDescription;

  set needDescription(bool value) {
    if (value != _needDescription) {
      _needDescription = value;
      markNeedsPaint();
    }
  }

  InspectorSelection _selection;

  InspectorSelection get selection => _selection;

  set selection(InspectorSelection value) {
    if (value != _selection) {
      if (attached) _selection.removeListener(markNeedsPaint);
      _selection = value;
      if (attached) _selection.addListener(markNeedsPaint);
      markNeedsPaint();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _selection.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _selection.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.addLayer(
      _InspectorOverlayLayer(
        selection: selection,
        needEdges: needEdges,
        needDescription: needDescription,
        overlayRect: offset & size,
      ),
    );
  }
}

class _InspectorOverlayLayer extends Layer {
  _InspectorOverlayLayer({
    required this.overlayRect,
    required this.selection,
    required this.needDescription,
    required this.needEdges,
  });

  final InspectorSelection selection;

  final bool needDescription;
  final bool needEdges;
  final Rect overlayRect;

  _InspectorOverlayRenderState? _lastState;

  ui.Picture? _picture;

  TextPainter? _textPainter;

  double? _lastMaxWidth;

  @override
  void dispose() {
    _picture?.dispose();
    _textPainter?.dispose();
    super.dispose();
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    if (!selection.active || selection.current == null) return;

    final info = _SelectionInfo(selection);
    final selected = _TransformedRect(selection.current!);
    final candidates = selection.candidates
        .where((c) => c != selection.current && c.attached)
        .map(_TransformedRect.new)
        .toList();

    final state = _InspectorOverlayRenderState(
      overlayRect: overlayRect,
      selected: selected,
      candidates: candidates,
      textDirection: TextDirection.ltr,
      message: needDescription ? info.message : '',
    );

    if (state != _lastState) {
      _lastState = state;
      _picture?.dispose();
      _picture = _buildPicture(state);
    }

    if (_picture != null) {
      builder.addPicture(layerOffset, _picture!);
    }
  }

  ui.Picture _buildPicture(_InspectorOverlayRenderState state) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, state.overlayRect);
    final size = state.overlayRect.size;

    final fillPaint = Paint()..color = _InspectorConstants.selectionFill;
    final borderPaint = Paint()
      ..color = _InspectorConstants.selectionBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = _InspectorConstants.strokeWidth;

    final selectedRect = state.selected.rect.deflate(0.5);
    canvas
      ..save()
      ..transform(state.selected.transform.storage)
      ..drawRect(selectedRect, fillPaint)
      ..drawRect(selectedRect, borderPaint)
      ..restore();

    if (needEdges) {
      for (final r in state.candidates) {
        canvas
          ..save()
          ..transform(r.transform.storage)
          ..drawRect(r.rect.deflate(0.5), borderPaint)
          ..restore();
      }
    }

    if (needDescription) {
      final globalRect = MatrixUtils.transformRect(
        state.selected.transform,
        state.selected.rect,
      );
      final target = Offset(globalRect.left, globalRect.center.dy);
      final verticalOffset =
          globalRect.height / 2 + _InspectorConstants.offsetFromWidget;
      _paintDescription(
        canvas,
        state.message,
        state.textDirection,
        target,
        verticalOffset,
        size,
      );
    }

    return recorder.endRecording();
  }

  void _paintDescription(
    Canvas canvas,
    String message,
    TextDirection textDirection,
    Offset target,
    double verticalOffset,
    Size size,
  ) {
    canvas.save();

    final viewList = WidgetsBinding.instance.platformDispatcher.views;
    if (viewList.isEmpty) {
      canvas.restore();
      return;
    }

    final view = viewList.first;
    final safeArea = EdgeInsets.fromViewPadding(
      view.padding,
      view.devicePixelRatio,
    );

    final maxWidth =
        size.width -
        safeArea.horizontal -
        2 *
            (_InspectorConstants.screenMargin +
                _InspectorConstants.tooltipPadding);
    final maxHeight =
        size.height -
        safeArea.vertical -
        2 *
            (_InspectorConstants.screenMargin +
                _InspectorConstants.tooltipPadding);
    final maxLines = math.min(
      _InspectorConstants.maxTooltipLines,
      (maxHeight / (_InspectorConstants.tooltipFontSize * 1.5)).floor(),
    );
    if (maxWidth <= 0 || maxLines < 1) {
      canvas.restore();
      return;
    }

    if (_textPainter == null ||
        _textPainter!.text?.toPlainText() != message ||
        _textPainter!.maxLines != maxLines ||
        _textPainter!.textDirection != textDirection ||
        _lastMaxWidth != maxWidth) {
      _lastMaxWidth = maxWidth;
      _textPainter?.dispose();
      _textPainter = TextPainter(
        maxLines: maxLines,
        ellipsis: '...',
        textDirection: textDirection,
        text: TextSpan(
          text: message,
          style: const TextStyle(
            color: _InspectorConstants.tooltipTextColor,
            fontSize: _InspectorConstants.tooltipFontSize,
            height: 1.5,
          ),
        ),
      )..layout(maxWidth: maxWidth);
    }

    final tooltipSize =
        _textPainter!.size +
        Offset(
          _InspectorConstants.tooltipPadding * 2,
          _InspectorConstants.tooltipPadding * 2,
        );

    var tipOffset = positionDependentBox(
      size: size,
      childSize: tooltipSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: false,
    );

    final aboveFits =
        (tipOffset.dy - safeArea.top) >= _InspectorConstants.screenMargin;

    if (!aboveFits) {
      tipOffset = positionDependentBox(
        size: size,
        childSize: tooltipSize,
        target: target,
        verticalOffset: verticalOffset,
        preferBelow: true,
      );
    }

    final isBelow = !aboveFits || tipOffset.dy > target.dy;

    tipOffset = Offset(
      tipOffset.dx.clamp(
        safeArea.left + _InspectorConstants.screenMargin,
        size.width -
            safeArea.right -
            _InspectorConstants.screenMargin -
            tooltipSize.width,
      ),
      tipOffset.dy.clamp(
        safeArea.top + _InspectorConstants.screenMargin,
        size.height -
            safeArea.bottom -
            _InspectorConstants.screenMargin -
            tooltipSize.height,
      ),
    );

    final bgPaint = Paint()..color = _InspectorConstants.tooltipBackground;
    canvas.drawRect(tipOffset & tooltipSize, bgPaint);

    _drawTooltipArrow(canvas, tipOffset, target, tooltipSize, isBelow, bgPaint);

    _textPainter!.paint(
      canvas,
      tipOffset +
          Offset(
            _InspectorConstants.tooltipPadding,
            _InspectorConstants.tooltipPadding,
          ),
    );
    canvas.restore();
  }

  void _drawTooltipArrow(
    Canvas canvas,
    Offset tipOffset,
    Offset target,
    Size tooltipSize,
    bool isBelow,
    Paint paint,
  ) {
    final size = math.min(
      _InspectorConstants.tooltipPadding * 2,
      tooltipSize.width / 4,
    );
    double y = isBelow ? tipOffset.dy : tipOffset.dy + tooltipSize.height;
    double x = target.dx.clamp(
      tipOffset.dx + size * 2,
      tipOffset.dx + tooltipSize.width - size * 2,
    );

    final wedge = [
      Offset(x - size, y),
      Offset(x + size, y),
      Offset(x, y + (isBelow ? -size : size)),
    ];
    canvas.drawPath(Path()..addPolygon(wedge, true), paint);
  }

  @override
  bool findAnnotations<S extends Object>(
    AnnotationResult<S> result,
    Offset localPosition, {
    required bool onlyFirst,
  }) => false;
}

class _TransformedRect {
  _TransformedRect(RenderObject object)
    : rect = object.semanticBounds,
      transform = object.getTransformTo(null);

  final Rect rect;

  final Matrix4 transform;

  @override
  bool operator ==(Object other) =>
      other is _TransformedRect &&
      rect == other.rect &&
      transform == other.transform;

  @override
  int get hashCode => Object.hash(rect, transform);
}

class _SelectionInfo {
  _SelectionInfo(this.selection);

  final InspectorSelection selection;

  RenderObject? get renderObject => selection.current;

  Element? get element => selection.currentElement;

  late final Map<String, dynamic>? jsonInfo = _readJsonInfo();

  Map<String, dynamic>? _readJsonInfo() {
    try {
      final jsonStr = WidgetInspectorService.instance.getSelectedSummaryWidget(
        null,
        '',
      );
      return json.decode(jsonStr) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  String? get description => jsonInfo?['description'] as String?;

  String? get filePath => jsonInfo?['creationLocation']?['file'] as String?;

  int? get line => jsonInfo?['creationLocation']?['line'] as int?;

  int? get column => jsonInfo?['creationLocation']?['column'] as int?;

  String get message {
    if (element == null || renderObject == null) {
      return 'No widget selected or information unavailable.';
    }
    final object = renderObject!;
    final bounds = MatrixUtils.transformRect(
      object.getTransformTo(null),
      object.semanticBounds,
    );

    return [
      description ?? element!.widget.toStringShort(),
      '${object.semanticBounds.size}',
      '${bounds.topLeft}',
      '${filePath ?? 'N/A'}:${line ?? 'N/A'}:${column ?? 'N/A'}',
    ].join('\n');
  }
}

class _InspectorOverlayRenderState {
  _InspectorOverlayRenderState({
    required this.overlayRect,
    required this.selected,
    required this.candidates,
    required this.textDirection,
    required this.message,
  });

  final Rect overlayRect;

  final _TransformedRect selected;

  final List<_TransformedRect> candidates;

  final TextDirection textDirection;

  final String message;

  @override
  bool operator ==(Object other) {
    return other is _InspectorOverlayRenderState &&
        overlayRect == other.overlayRect &&
        selected == other.selected &&
        listEquals(candidates, other.candidates) &&
        textDirection == other.textDirection &&
        message == other.message;
  }

  @override
  int get hashCode => Object.hash(
    overlayRect,
    selected,
    Object.hashAll(candidates),
    textDirection,
    message,
  );
}
