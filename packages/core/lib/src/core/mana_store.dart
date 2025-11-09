import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'mana_state.dart';

class ManaStore {
  static ManaStore? _instance;

  static ManaStore get instance {
    _instance ??= ManaStore._();
    return _instance!;
  }

  ManaStore._();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  SharedPreferences get prefs {
    if (!_isInitialized) {
      throw Exception('ManaStore must be initialized first. Call init() before using prefs.');
    }
    return _prefs!;
  }

  ManaState getManaState() {
    final floatActionButtonSize = prefs.getDouble('mana_floating_button_size');
    final floatActionButtonOpacity = prefs.getDouble('mana_floating_button_opacity');

    return ManaState(
      initialFloatingButtonSize: floatActionButtonSize,
      initialFloatingButtonOpacity: floatActionButtonOpacity,
    );
  }

  Future<void> setManaState(ManaState manaState) async {
    await prefs.setDouble('mana_floating_button_size', manaState.floatingButtonSize.value);
    await prefs.setDouble('mana_floating_button_opacity', manaState.floatingButtonOpacity.value);
  }

  (double, double) getFloatActionButtonPosition() {
    final x = prefs.getDouble('mana_floating_button_x') ?? 0;
    final y = prefs.getDouble('mana_floating_button_y') ?? 0;
    return (x, y);
  }

  Future<void> setFloatActionButtonPosition(double x, double y) async {
    await prefs.setDouble('mana_floating_button_x', double.parse(x.toStringAsFixed(1)));
    await prefs.setDouble('mana_floating_button_y', double.parse(y.toStringAsFixed(1)));
  }
}
