import 'package:flutter/material.dart';
import 'package:flutter_mana/flutter_mana.dart';

import 'model.dart' show Model;

class ModelTile extends StatelessWidget {
  final Model model;
  final GestureTapCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const ModelTile({super.key, required this.model, this.onTap, this.onCopy, this.onDelete});

  @override
  Widget build(BuildContext context) {
    // 根据kind类型设置不同的文字颜色
    Color getTextColorByKind(String kind) {
      switch (kind.toLowerCase()) {
        case 'double':
          return Colors.blue;
        case 'bool':
          return Colors.green;
        case 'int':
          return Colors.orange;
        case 'string':
          return Colors.purple;
        default:
          return Colors.red;
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: const Border(),
      onTap: onTap,
      leading: Text(
        model.kind.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: getTextColorByKind(model.kind),
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
            initialIcon: Icons.copy,
            size: 14,
            onPressed: onCopy,
          ),
          CheckIconButton(
            initialIcon: Icons.delete_outline,
            size: 16,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
