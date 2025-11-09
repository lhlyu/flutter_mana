import 'package:flutter/material.dart';

/// 轻量级“点击后显示 √，N 秒后自动恢复”的 IconButton
/// [onPressed] 返回 Future 时，按钮会等待 Future 完成再复位
@immutable
class CheckIconButton extends StatelessWidget {
  final IconData initialIcon;
  final IconData changedIcon;
  final Color? iconColor;
  final double? size;
  final ButtonStyle? style;
  final Duration resetDuration;
  final VoidCallback? onPressed;

  const CheckIconButton({
    super.key,
    required this.initialIcon,
    this.changedIcon = Icons.check,
    this.iconColor,
    this.size,
    this.style,
    this.resetDuration = const Duration(seconds: 2),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder:
          (_, checked, __) => IconButton(
            icon: Icon(checked ? changedIcon : initialIcon, size: size, color: iconColor),
            style: style,
            onPressed: () async {
              if (checked) return;
              try {
                onPressed?.call();
                notifier.value = true;
              } finally {
                Future.delayed(resetDuration, () {
                  notifier.value = false;
                });
              }
            },
          ),
    );
  }
}
