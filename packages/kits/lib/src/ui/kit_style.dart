import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_widgets.dart';

abstract final class KitStyle {
  static const surface = ManaStyle.surface;
  static const text = ManaStyle.text;
  static const muted = ManaStyle.muted;
  static const border = Color(0xFFE0E4E7);
  static const subtle = Color(0xFFF4F6F8);
  static const accent = Color(0xFF2864A0);
  static const danger = Color(0xFFB42318);
  static const success = Color(0xFF147D52);
  static const warning = Color(0xFF996200);
  static const code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.5,
    color: text,
  );
}
