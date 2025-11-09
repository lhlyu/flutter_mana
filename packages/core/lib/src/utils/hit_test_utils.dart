import 'package:flutter/rendering.dart';
import 'package:flutter_mana/flutter_mana.dart';

/// A utility class for performing hit testing on the Flutter render tree.
///
/// 一个用于在 Flutter 渲染树上执行点击测试的工具类。
class HitTestUtils {
  /// Performs a hit test at the given [position] on the render tree rooted at `manaRootKey`.
  ///
  /// 在以 `manaRootKey` 为根的渲染树上，在给定 [position] 执行点击测试。
  ///
  /// Returns a sorted list of [RenderObject]s that intersect with the given [position],
  /// ordered by their area in ascending order (smallest to largest).
  ///
  /// 返回与给定 [position] 相交的 [RenderObject] 列表，
  /// 按其面积升序（从小到大）排序。
  static List<RenderObject> hitTest(Offset position) {
    final List<RenderObject> hitResults = <RenderObject>[];

    /// Get the root [RenderObject] from the `manaRootKey`'s current context.
    ///
    /// 从 `manaRootKey` 的当前上下文获取根 [RenderObject]。
    final RenderObject? rootRenderObject =
        manaRootKey.currentContext?.findRenderObject();

    /// If the root render object is a [RenderBox], perform a box hit test.
    ///
    /// 如果根渲染对象是 [RenderBox]，则执行盒子点击测试。
    if (rootRenderObject is RenderBox) {
      final BoxHitTestResult result = BoxHitTestResult();

      /// Perform the hit test on the root render object.
      ///
      /// 在根渲染对象上执行点击测试。
      rootRenderObject.hitTest(result, position: position);

      /// Iterate through the hit test path and collect all [RenderObject]s.
      ///
      /// 遍历点击测试路径并收集所有 [RenderObject]。
      for (final HitTestEntry entry in result.path) {
        if (entry.target is RenderObject) {
          hitResults.add(entry.target as RenderObject);
        }
      }
    }

    /// Sort the [hitResults] by the area of their semantic bounds in ascending order.
    /// This means smaller widgets (likely more specific ones) will appear first.
    ///
    /// 按语义边界的面积升序排序 [hitResults]。
    /// 这意味着较小的组件（可能是更具体的组件）将首先出现。
    hitResults.sort((a, b) {
      final Size sizeA = a.semanticBounds.size;
      final Size sizeB = b.semanticBounds.size;
      final double areaA = sizeA.width * sizeA.height;
      final double areaB = sizeB.width * sizeB.height;
      return areaA.compareTo(areaB);
    });

    return hitResults;
  }
}
