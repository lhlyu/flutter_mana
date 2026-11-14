import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

@immutable
final class ManaSettings {
  final double buttonSize;
  final double buttonOpacity;
  final Offset? buttonPosition;

  const ManaSettings({
    this.buttonSize = 50,
    this.buttonOpacity = 1,
    this.buttonPosition,
  });

  factory ManaSettings.fromMap(Map<String, Object?> values) {
    double read(String key, double fallback) => switch (values[key]) {
      final num value when value.isFinite => value.toDouble(),
      _ => fallback,
    };
    final x = read('mana_floating_button_x', double.nan);
    final y = read('mana_floating_button_y', double.nan);
    return ManaSettings(
      buttonSize: read('mana_floating_button_size', 50).clamp(30, 100),
      buttonOpacity: read('mana_floating_button_opacity', 1).clamp(0.1, 1),
      buttonPosition: x.isFinite && y.isFinite ? Offset(x, y) : null,
    );
  }

  ManaSettings copyWith({
    double? buttonSize,
    double? buttonOpacity,
    Offset? buttonPosition,
  }) => ManaSettings(
    buttonSize: buttonSize ?? this.buttonSize,
    buttonOpacity: buttonOpacity ?? this.buttonOpacity,
    buttonPosition: buttonPosition ?? this.buttonPosition,
  );

  Map<String, double?> toMap() => {
    'mana_floating_button_size': buttonSize,
    'mana_floating_button_opacity': buttonOpacity,
    'mana_floating_button_x': buttonPosition?.dx,
    'mana_floating_button_y': buttonPosition?.dy,
  };
}
