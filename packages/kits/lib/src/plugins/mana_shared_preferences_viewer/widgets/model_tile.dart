import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';

import 'model.dart' show Model;

// 颜色表，编译期常量
const Map<String, Color> _colorMap = {
  'double': Colors.blue,
  'bool': Colors.green,
  'int': Colors.orange,
  'string': Colors.purple,
};

class ModelTile extends StatelessWidget {
  final Model model;
  final GestureTapCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const ModelTile({super.key, required this.model, this.onTap, this.onCopy, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _colorMap[model.kind.toLowerCase()] ?? Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: const Border(),
      onTap: onTap,
      leading: Text(
        model.kind.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      title: Text(
        model.key,
        maxLines: 1,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          model.value,
          maxLines: 1,
          style: TextStyle(color: Colors.black87, fontSize: 12, overflow: TextOverflow.ellipsis),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckIconButton(
            initialIcon: KitIcons.copy,
            changedIcon: KitIcons.copy_success,
            size: 14,
            onPressed: onCopy,
          ),
          CheckIconButton(
            initialIcon: KitIcons.clear,
            changedIcon: KitIcons.copy_success,
            size: 16,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
