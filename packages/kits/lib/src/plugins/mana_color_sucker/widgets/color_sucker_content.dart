import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';

class ColorSuckerContent extends StatefulWidget {
  final Color color;
  final ValueChanged<double>? onMagnificationChanged;

  const ColorSuckerContent({
    super.key,
    required this.color,
    this.onMagnificationChanged,
  });

  @override
  State<ColorSuckerContent> createState() => _ColorSuckerContentState();
}

class _ColorSuckerContentState extends State<ColorSuckerContent>
    with I18nMixin {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = widget.color;
  }

  @override
  void didUpdateWidget(covariant ColorSuckerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      setState(() {
        _color = widget.color;
      });
    }
  }

  String get colorHex {
    if (_color == Colors.transparent) {
      return '#000000';
    }
    return '#${_color.toARGB32().toRadixString(16).substring(2)}';
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: colorHex));
  }

  double _zoomLevel = 10;
  final List<double> _zoomOptions = [5, 10, 15, 20, 25, 30];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t('color_sucker.magnification'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_zoomLevel.toInt()}x',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          Slider(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            value: _zoomLevel,
            min: _zoomOptions.first,
            max: _zoomOptions.last,
            divisions: _zoomOptions.length - 1,
            label: '${_zoomLevel.toInt()}x',
            onChanged: (value) {
              // 吸附到最近的预设值（可选）
              _zoomLevel = _zoomOptions.reduce(
                (a, b) => (value - a).abs() < (value - b).abs() ? a : b,
              );
              widget.onMagnificationChanged?.call(_zoomLevel);
              setState(() {});
            },
          ),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _color == Colors.transparent ? Colors.black : _color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  colorHex,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CheckIconButton(
                initialIcon: KitIcons.copy,
                changedIcon: KitIcons.copy_success,
                onPressed: _copyToClipboard,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
