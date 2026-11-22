import 'package:flutter/widgets.dart';

abstract final class ManaStyle {
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF212121);
  static const muted = Color(0xFF757575);
  static const border = Color(0xFFBDBDBD);
  static const accent = Color(0xFF455A64);
  static const danger = Color(0xFFE53935);
  static const transparent = Color(0x00000000);
  static const shadow = Color(0x33000000);
  static const textStyle = TextStyle(
    color: text,
    fontSize: 14,
    height: 1.4,
    decoration: .none,
  );
}
