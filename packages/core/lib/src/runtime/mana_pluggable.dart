import 'dart:async';

import 'package:flutter/widgets.dart';

import '../widgets/floating_button/icon.dart' as mana;

enum ManaPresentation { window, overlay, action }

abstract class ManaPluggable {
  String get name;
  String getLocalizedDisplayName(Locale locale);
  ImageProvider get iconImageProvider => mana.iconImage;

  Widget buildIcon(BuildContext context, {double size = 40}) =>
      Image(image: iconImageProvider, width: size, height: size, fit: .contain);
  bool get isSupported => true;
  ManaPresentation get presentation => .window;

  /// Initialize resources before activation.
  FutureOr<void> initialize() {}

  /// Start the active session.
  FutureOr<void> onTrigger() {}

  /// Stop the session; retain resources until dispose().
  FutureOr<void> deactivate() {}

  /// Release owned resources.
  FutureOr<void> dispose() {}

  /// Action-only plugins do not need to implement a widget.
  Widget? buildWidget(BuildContext context) => null;
}
