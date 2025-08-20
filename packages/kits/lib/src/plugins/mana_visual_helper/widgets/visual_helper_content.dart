import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

class VisualHelperContent extends StatefulWidget {
  const VisualHelperContent({super.key});

  @override
  State<VisualHelperContent> createState() => _VisualHelperContentState();
}

class _VisualHelperContentState extends State<VisualHelperContent> with I18nMixin {
  double _raw = 1;
  double get _speed => 1 / _raw; // 实际倍速（倒数）

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

  @override
  void dispose() {
    timeDilation = 1;
    debugPaintSizeEnabled = false;
    debugRepaintRainbowEnabled = false;
    debugInvertOversizedImages = false;
    markWholeRenderTreeNeedsPaint();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动画减速（标题 + 文案 + Slider）
          Row(
            children: [
              Text(t('visual_helper.animate_speed'), style: TextStyle(fontSize: 14)),
              const Spacer(),
              Text('×${_raw.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Slider(
            value: _raw,
            min: 0.1,
            max: 2,
            divisions: 19,
            onChangeStart: (value) {
              timeDilation = 1;
            },
            onChangeEnd: (value) {
              timeDilation = _speed;
            },
            onChanged: (value) {
              setState(() {
                _raw = value;
              });
            },
          ),
          const SizedBox(height: 8),

          // 三项紧凑行
          _compactRow(t('visual_helper.layout_bounds'), t('visual_helper.show_widget_borders'), debugPaintSizeEnabled,
              (v) {
            setState(() => debugPaintSizeEnabled = v);
            markWholeRenderTreeNeedsPaint();
          }),
          _compactRow(t('visual_helper.repaint_highlight'), t('visual_helper.frame_repaint_highlight'),
              debugRepaintRainbowEnabled, (v) {
            setState(() => debugRepaintRainbowEnabled = v);
            markWholeRenderTreeNeedsPaint();
          }),
          _compactRow(t('visual_helper.invert_oversized_images'), t('visual_helper.invert_oversized_images_label'),
              debugInvertOversizedImages, (v) {
            setState(() => debugInvertOversizedImages = v);
            markWholeRenderTreeNeedsPaint();
          }),
        ],
      ),
    );
  }

  Widget _compactRow(String title, String desc, bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ],
      ),
    );
  }
}
