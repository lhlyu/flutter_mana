import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// === 常量定义 ===
/// Defines constants used for the inspector overlay, such as colors, sizes, and spacing.
///
/// 定义检查器覆盖层使用的常量，例如颜色、大小和间距。
abstract final class _InspectorConstants {
  /// Maximum number of lines for the tooltip text.
  ///
  /// 工具提示文本的最大行数。
  static const int maxTooltipLines = 10;

  /// Margin from the screen edges for the tooltip.
  ///
  /// 工具提示距离屏幕边缘的边距。
  static const double screenMargin = 10.0;

  /// Padding inside the tooltip background.
  ///
  /// 工具提示背景内部的填充。
  static const double tooltipPadding = 8.0;

  /// Vertical offset from the selected widget to the tooltip.
  ///
  /// 从选中组件到工具提示的垂直偏移。
  static const double offsetFromWidget = 9.0;

  /// Font size for the tooltip text.
  ///
  /// 工具提示文本的字体大小。
  static const double tooltipFontSize = 12.0;

  /// Stroke width for the selection border.
  ///
  /// 选中边框的描边宽度。
  static const double strokeWidth = 1.0;

  /// Background color of the tooltip.
  ///
  /// 工具提示的背景颜色。
  static const Color tooltipBackground = Color.fromARGB(230, 60, 60, 60);

  /// Text color of the tooltip.
  ///
  /// 工具提示的文本颜色。
  static const Color tooltipTextColor = Color(0xFFFFFFFF);

  /// Fill color for the selected widget's overlay.
  ///
  /// 选中组件覆盖层的填充颜色。
  static const Color selectionFill = Color.fromARGB(128, 128, 128, 255);

  /// Border color for the selected widget's overlay.
  ///
  /// 选中组件覆盖层的边框颜色。
  static const Color selectionBorder = Color.fromARGB(128, 64, 64, 128);
}

// === Widget 层 ===
/// A [LeafRenderObjectWidget] that displays an overlay for inspecting UI elements.
/// It renders a selection box around a chosen widget and optionally shows edge outlines for candidates and a description tooltip.
///
/// 一个 [LeafRenderObjectWidget]，用于显示用于检查 UI 元素的覆盖层。
/// 它在选定的组件周围渲染一个选择框，并可选地显示候选组件的边缘轮廓和描述工具提示。
class InspectorOverlay extends LeafRenderObjectWidget {
  /// Creates an [InspectorOverlay].
  ///
  /// 创建一个 [InspectorOverlay]。
  const InspectorOverlay({
    super.key,
    required this.selection,
    this.needEdges = true,
    this.needDescription = true,
  });

  /// The current selection state for the inspector.
  ///
  /// 检查器的当前选择状态。
  final InspectorSelection selection;

  /// Whether to draw edges for candidate widgets.
  ///
  /// 是否绘制候选组件的边缘。
  final bool needEdges;

  /// Whether to display a description tooltip for the selected widget.
  ///
  /// 是否显示选中组件的描述工具提示。
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

// === RenderObject 层 ===
/// A [RenderBox] that handles the layout and painting of the inspector overlay.
/// It manages the properties related to selection, edge visibility, and description visibility,
/// and triggers repaints when these properties change.
///
/// 一个 [RenderBox]，负责检查器覆盖层的布局和绘制。
/// 它管理与选择、边缘可见性和描述可见性相关的属性，并在这些属性更改时触发重新绘制。
class RenderInspectorOverlay extends RenderBox {
  /// Creates a [RenderInspectorOverlay].
  ///
  /// 创建一个 [RenderInspectorOverlay]。
  RenderInspectorOverlay({
    required InspectorSelection selection,
    required bool needEdges,
    required bool needDescription,
  }) : _selection = selection,
       _needEdges = needEdges,
       _needDescription = needDescription;

  bool _needEdges;

  /// Whether to draw edges for candidate widgets.
  ///
  /// 是否绘制候选组件的边缘。
  bool get needEdges => _needEdges;

  set needEdges(bool value) {
    if (value != _needEdges) {
      _needEdges = value;
      markNeedsPaint();
    }
  }

  bool _needDescription;

  /// Whether to display a description tooltip for the selected widget.
  ///
  /// 是否显示选中组件的描述工具提示。
  bool get needDescription => _needDescription;

  set needDescription(bool value) {
    if (value != _needDescription) {
      _needDescription = value;
      markNeedsPaint();
    }
  }

  InspectorSelection _selection;

  /// The current selection state for the inspector.
  ///
  /// 检查器的当前选择状态。
  InspectorSelection get selection => _selection;

  set selection(InspectorSelection value) {
    if (value != _selection) {
      _selection = value;
      markNeedsPaint();
    }
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

// === Layer 层：真正负责绘制 ===
/// A custom [Layer] responsible for the actual painting of the inspector overlay.
/// It draws the selection box, candidate edges, and the tooltip based on the current selection.
///
/// 一个自定义的 [Layer]，负责检查器覆盖层的实际绘制。
/// 它根据当前选择绘制选择框、候选边缘和工具提示。
class _InspectorOverlayLayer extends Layer {
  /// Creates an [_InspectorOverlayLayer].
  ///
  /// 创建一个 [_InspectorOverlayLayer]。
  _InspectorOverlayLayer({
    required this.overlayRect,
    required this.selection,
    required this.needDescription,
    required this.needEdges,
  });

  /// The current selection state.
  ///
  /// 当前选择状态。
  final InspectorSelection selection;

  /// Whether to display a description tooltip.
  ///
  /// 是否显示描述工具提示。
  final bool needDescription;

  /// Whether to draw edges for candidate widgets.
  ///
  /// 是否绘制候选组件的边缘。
  final bool needEdges;

  /// The rectangle representing the bounds of the overlay.
  ///
  /// 表示覆盖层边界的矩形。
  final Rect overlayRect;

  /// The last rendering state used to determine if a repaint is needed.
  ///
  /// 上次用于判断是否需要重绘的渲染状态。
  _InspectorOverlayRenderState? _lastState;

  /// The [ui.Picture] containing the cached drawing commands for the overlay.
  ///
  /// 包含覆盖层缓存绘制命令的 [ui.Picture]。
  ui.Picture? _picture;

  /// The [TextPainter] used for layout and painting the tooltip text.
  ///
  /// 用于布局和绘制工具提示文本的 [TextPainter]。
  TextPainter? _textPainter;

  /// The last calculated maximum width for the tooltip, used for caching.
  ///
  /// 工具提示上次计算的最大宽度，用于缓存。
  double? _lastMaxWidth;

  @override
  void dispose() {
    _picture?.dispose(); // Disposes of the cached picture to free up resources.
    super.dispose();
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    /// If no selection is active or no current element is selected, do nothing.
    ///
    /// 如果没有活动选择或没有当前选中的元素，则不执行任何操作。
    if (!selection.active || selection.current == null) return;

    final info = _SelectionInfo(selection);
    final selected = _TransformedRect(selection.current!);
    final candidates =
        selection.candidates
            .where((c) => c != selection.current && c.attached)
            .map(_TransformedRect.new)
            .toList();

    final state = _InspectorOverlayRenderState(
      overlayRect: overlayRect,
      selected: selected,
      candidates: candidates,
      textDirection: TextDirection.ltr,
      selectionInfo: info,
    );

    /// If the current state is different from the last rendered state, recreate the picture.
    ///
    /// 如果当前状态与上次渲染的状态不同，则重新创建图像。
    if (state != _lastState) {
      _lastState = state;
      _picture?.dispose(); // Cleans up the old picture.
      _picture = _buildPicture(state);
    }

    /// Add the cached picture to the scene builder if it exists.
    ///
    /// 如果存在缓存的图像，则将其添加到场景构建器。
    if (_picture != null) {
      builder.addPicture(layerOffset, _picture!);
    }
  }

  /// Builds and returns a [ui.Picture] containing all the drawing commands for the overlay.
  /// This method performs the actual drawing of the selection box, candidate outlines, and tooltip.
  ///
  /// 构建并返回一个包含覆盖层所有绘制命令的 [ui.Picture]。
  /// 此方法执行选择框、候选轮廓和工具提示的实际绘制。
  ui.Picture _buildPicture(_InspectorOverlayRenderState state) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, state.overlayRect);
    final size = state.overlayRect.size;

    // Draw the selection box.
    // 绘制选中框。
    final fillPaint = Paint()..color = _InspectorConstants.selectionFill;
    final borderPaint =
        Paint()
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

    // Draw borders for candidate elements if `needEdges` is true.
    // 如果 `needEdges` 为 true，则绘制候选元素的边框。
    if (needEdges) {
      for (final r in state.candidates) {
        canvas
          ..save()
          ..transform(r.transform.storage)
          ..drawRect(r.rect.deflate(0.5), borderPaint)
          ..restore();
      }
    }

    // Draw the text description tooltip if `needDescription` is true.
    // 如果 `needDescription` 为 true，则绘制文本描述工具提示。
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
        state.selectionInfo.message,
        state.textDirection,
        target,
        verticalOffset,
        size,
        globalRect,
      );
    }

    return recorder.endRecording();
  }

  /// Paints the description tooltip on the canvas.
  /// It calculates the optimal position for the tooltip to avoid overlapping with the selected widget or screen edges.
  ///
  /// 在画布上绘制描述工具提示。
  /// 它计算工具提示的最佳位置，以避免与选定组件或屏幕边缘重叠。
  void _paintDescription(
    Canvas canvas,
    String message,
    TextDirection textDirection,
    Offset target,
    double verticalOffset,
    Size size,
    Rect targetRect,
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

    // Calculate the maximum width for the tooltip text to fit within screen margins.
    // 计算工具提示文本的最大宽度，以适应屏幕边距。
    final maxWidth =
        size.width -
        2 *
            (_InspectorConstants.screenMargin +
                _InspectorConstants.tooltipPadding);

    /// If the text content or max width has changed, re-layout the text painter.
    ///
    /// 如果文本内容或最大宽度已更改，则重新布局文本 painter。
    if (_textPainter == null ||
        _textPainter!.text?.toPlainText() != message ||
        _lastMaxWidth != maxWidth) {
      _lastMaxWidth = maxWidth;
      _textPainter = TextPainter(
        maxLines: _InspectorConstants.maxTooltipLines,
        ellipsis: '...', // Ellipsis for text overflow.
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

    /// Calculate the total size of the tooltip including padding.
    ///
    /// 计算包含填充在内的工具提示的总大小。
    final tooltipSize =
        _textPainter!.size +
        Offset(
          _InspectorConstants.tooltipPadding * 2,
          _InspectorConstants.tooltipPadding * 2,
        );

    // First, attempt to position the tooltip above the target widget.
    // 首先，尝试将工具提示放置在目标组件上方。
    var tipOffset = positionDependentBox(
      size: size,
      // Size of the overlay.
      childSize: tooltipSize,
      // Size of the tooltip.
      target: target,
      // Target point (e.g., center of the selected widget).
      verticalOffset: verticalOffset,
      // Vertical offset from the target.
      preferBelow: false, // Prefer placing above.
    );

    /// Check if the tooltip fits above the target, considering safe areas and screen margins.
    ///
    /// 检查工具提示是否适合目标上方，同时考虑安全区域和屏幕边距。
    final aboveFits =
        (tipOffset.dy - safeArea.top) >= _InspectorConstants.screenMargin;

    // If it doesn't fit above, try placing it below.
    // 如果上方空间不足，改为下方。
    if (!aboveFits) {
      tipOffset = positionDependentBox(
        size: size,
        childSize: tooltipSize,
        target: target,
        verticalOffset: verticalOffset,
        preferBelow: true, // Prefer placing below.
      );
    }

    /// Determine if the tooltip is placed below the target (either initially or after adjustment).
    ///
    /// 确定工具提示是否放置在目标下方（无论是初始放置还是调整后）。
    final isBelow = !aboveFits || tipOffset.dy > target.dy;

    // Clamp the tooltip offset to ensure it stays within the screen's safe area and margins.
    // 限制工具提示偏移量，确保它停留在屏幕安全区域和边距内。
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

    /// Draw the background rectangle for the tooltip.
    ///
    /// 绘制工具提示的背景矩形。
    final bgPaint = Paint()..color = _InspectorConstants.tooltipBackground;
    canvas.drawRect(tipOffset & tooltipSize, bgPaint);

    /// Draw the arrow connecting the tooltip to the selected widget.
    ///
    /// 绘制连接工具提示和选定组件的箭头。
    _drawTooltipArrow(canvas, tipOffset, target, tooltipSize, isBelow, bgPaint);

    /// Paint the text content of the tooltip.
    ///
    /// 绘制工具提示的文本内容。
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

  /// Draws an arrow that points from the tooltip to the target widget.
  ///
  /// 绘制从工具提示指向目标组件的箭头。
  void _drawTooltipArrow(
    Canvas canvas,
    Offset tipOffset,
    Offset target,
    Size tooltipSize,
    bool isBelow,
    Paint paint,
  ) {
    final size = _InspectorConstants.tooltipPadding * 2;
    double y = isBelow ? tipOffset.dy : tipOffset.dy + tooltipSize.height;
    double x = target.dx.clamp(
      tipOffset.dx + size * 2,
      tipOffset.dx + tooltipSize.width - size * 2,
    );

    /// Define the vertices of the arrow wedge.
    ///
    /// 定义箭头楔形的顶点。
    final wedge = [
      Offset(x - size, y),
      Offset(x + size, y),
      Offset(
        x,
        y + (isBelow ? -size : size),
      ), // Adjust vertical position based on `isBelow`.
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

// === 辅助结构 ===
/// Represents a rectangle and its transformation matrix for a [RenderObject].
/// Used to store the bounds and global transform of selected or candidate widgets.
///
/// 表示 [RenderObject] 的矩形及其变换矩阵。
/// 用于存储选定或候选组件的边界和全局变换。
class _TransformedRect {
  /// Creates a [_TransformedRect] from a [RenderObject].
  ///
  /// 从 [RenderObject] 创建一个 [_TransformedRect]。
  _TransformedRect(RenderObject object)
    : rect = object.semanticBounds,
      transform = object.getTransformTo(
        null,
      ); // Get the transform to the root coordinate system.

  /// The local bounds of the [RenderObject].
  ///
  /// [RenderObject] 的本地边界。
  final Rect rect;

  /// The transformation matrix from the [RenderObject]'s coordinate system to the global coordinate system.
  ///
  /// 从 [RenderObject] 坐标系到全局坐标系的变换矩阵。
  final Matrix4 transform;

  @override
  bool operator ==(Object other) =>
      other is _TransformedRect &&
      rect == other.rect &&
      transform == other.transform;

  @override
  int get hashCode => Object.hash(rect, transform);
}

/// Provides detailed information about the currently selected widget,
/// including its description, size, and source code location.
///
/// 提供有关当前选定组件的详细信息，
/// 包括其描述、大小和源代码位置。
class _SelectionInfo {
  /// Creates a [_SelectionInfo] based on an [InspectorSelection].
  ///
  /// 基于 [InspectorSelection] 创建一个 [_SelectionInfo]。
  _SelectionInfo(this.selection);

  /// The inspector selection object.
  ///
  /// 检查器选择对象。
  final InspectorSelection selection;

  /// The currently selected [RenderObject].
  ///
  /// 当前选定的 [RenderObject]。
  RenderObject? get renderObject => selection.current;

  /// The currently selected [Element].
  ///
  /// 当前选定的 [Element]。
  Element? get element => selection.currentElement;

  /// Retrieves a summary of the selected widget as a JSON map using [WidgetInspectorService].
  /// Returns `null` if an error occurs during decoding.
  ///
  /// 使用 [WidgetInspectorService] 将选定组件的摘要作为 JSON 映射检索。
  /// 如果解码过程中发生错误，则返回 `null`。
  Map<String, dynamic>? get jsonInfo {
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

  /// The description of the selected widget from the JSON info.
  ///
  /// 从 JSON 信息中获取的选定组件的描述。
  String? get description => jsonInfo?['description'] as String?;

  /// The file path where the selected widget was created.
  ///
  /// 创建选定组件的文件路径。
  String? get filePath => jsonInfo?['creationLocation']?['file'] as String?;

  /// The line number where the selected widget was created.
  ///
  /// 创建选定组件的行号。
  int? get line => jsonInfo?['creationLocation']?['line'] as int?;

  /// The column number where the selected widget was created.
  ///
  /// 创建选定组件的列号。
  int? get column => jsonInfo?['creationLocation']?['column'] as int?;

  /// Generates a formatted message string containing information about the selected widget.
  ///
  /// 生成包含有关选定组件信息的格式化消息字符串。
  String get message {
    if (element == null || renderObject == null) {
      return 'No widget selected or information unavailable.';
    }
    final box = renderObject as RenderBox;

    // 左上角坐标
    final globalOffset = box.localToGlobal(Offset.zero);

    // 元素尺寸
    final size = box.size;

    return [
      description,
      '$size',
      '$globalOffset',
      '${filePath ?? 'N/A'}:${line ?? 'N/A'}:${column ?? 'N/A'}',
    ].join('\n');
  }
}

/// Represents the rendering state of the inspector overlay,
/// used to optimize drawing by checking for changes in relevant properties.
///
/// 表示检查器覆盖层的渲染状态，
/// 用于通过检查相关属性的变化来优化绘制。
class _InspectorOverlayRenderState {
  /// Creates an [_InspectorOverlayRenderState].
  ///
  /// 创建一个 [_InspectorOverlayRenderState]。
  _InspectorOverlayRenderState({
    required this.overlayRect,
    required this.selected,
    required this.candidates,
    required this.textDirection,
    required this.selectionInfo,
  });

  /// The rectangle representing the bounds of the overlay.
  ///
  /// 表示覆盖层边界的矩形。
  final Rect overlayRect;

  /// The transformed rectangle of the selected widget.
  ///
  /// 选定组件的变换后矩形。
  final _TransformedRect selected;

  /// A list of transformed rectangles for candidate widgets.
  ///
  /// 候选组件的变换后矩形列表。
  final List<_TransformedRect> candidates;

  /// The text direction for rendering text.
  ///
  /// 渲染文本的文本方向。
  final TextDirection textDirection;

  /// Information about the current selection.
  ///
  /// 有关当前选择的信息。
  final _SelectionInfo selectionInfo;

  @override
  bool operator ==(Object other) {
    return other is _InspectorOverlayRenderState &&
        overlayRect == other.overlayRect &&
        selected == other.selected &&
        listEquals(
          candidates,
          other.candidates,
        ) && // Deep comparison for the list of candidates.
        textDirection == other.textDirection &&
        selectionInfo.message ==
            other
                .selectionInfo
                .message; // Compare by message as _SelectionInfo itself can be complex.
  }

  @override
  int get hashCode => Object.hash(
    overlayRect,
    selected,
    Object.hashAll(candidates),
    textDirection,
    selectionInfo.message,
  );
}
