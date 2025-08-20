import 'dart:async';

import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final FutureOr<void> Function()? onPressed;

  const CustomButton({
    super.key,
    required this.text,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.onPressed,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;

    setState(() => _isLoading = true);

    try {
      final result = widget.onPressed!();
      if (result is Future) {
        await result;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(backgroundColor: widget.backgroundColor, foregroundColor: widget.foregroundColor),
      child: Text(widget.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}
