import 'dart:async';

import 'package:flutter/widgets.dart';

/// Presentation intent, independent of any design system.
enum ManaPresentation { window, overlay, action }

abstract class ManaPluggable {
  String get name;
  String getLocalizedDisplayName(Locale locale);
  ImageProvider get iconImageProvider;
  bool get isSupported => true;
  ManaPresentation get presentation => .window;

  /// Initialize non-visual resources. Each registry entry runs this once.
  FutureOr<void> initialize() {}

  /// Called on explicit activation, after initialization succeeds.
  FutureOr<void> onTrigger() {}

  /// Stop work associated with the active session (not final resource disposal).
  FutureOr<void> deactivate() {}

  /// Release subscriptions, connections and other resources owned by this plugin.
  FutureOr<void> dispose() {}

  /// Action-only plugins do not need to implement a widget.
  Widget? buildWidget(BuildContext context) => null;
}
