import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

/// All built-in windows share keyboard avoidance and a scrollable compact layout.
class KitWindow extends StatelessWidget {
  const KitWindow({
    super.key,
    required this.name,
    this.content,
    this.barrier,
    this.setting,
    this.initialWidth,
    this.initialHeight,
    this.position = .normal,
    this.drag = true,
    this.showBarrier = true,
    this.maintainContent = true,
  });
  final String name;
  final Widget? content;
  final Widget? barrier;
  final Widget? setting;
  final double? initialWidth;
  final double? initialHeight;
  final PositionType position;
  final bool drag;
  final bool showBarrier;
  final bool maintainContent;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final view = View.of(context);
    final root = ManaScope.read(context).rootKey.currentContext
        ?.findRenderObject();
    var overlap = 0.0;
    if (media.viewInsets.bottom > 0 && root is RenderBox && root.hasSize) {
      final bottom = root.localToGlobal(Offset(0, root.size.height)).dy;
      final keyboardTop =
          view.physicalSize.height / view.devicePixelRatio -
          media.viewInsets.bottom;
      overlap = (bottom - keyboardTop).clamp(
        0,
        math.max(0, media.size.height - 80),
      );
    }
    return MediaQuery(
      data: media.copyWith(
        size: Size(media.size.width, media.size.height - overlap),
        viewInsets: .zero,
      ),
      child: ManaFloatingWindow(
        name: name,
        initialWidth: initialWidth,
        initialHeight: initialHeight,
        position: position,
        drag: drag,
        showBarrier: showBarrier,
        maintainContent: maintainContent,
        barrier: barrier,
        content: content == null ? null : _CompactViewport(child: content!),
        setting: setting == null ? null : _CompactViewport(child: setting!),
      ),
    );
  }
}

class _CompactViewport extends StatelessWidget {
  const _CompactViewport({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minHeight =
          260.0 *
          (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 3.0);
      return SingleChildScrollView(
        child: SizedBox(
          height: math.max(minHeight, constraints.maxHeight),
          child: child,
        ),
      );
    },
  );
}
