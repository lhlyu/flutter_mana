import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

class ScreenInfoContent extends StatelessWidget {
  const ScreenInfoContent({super.key, required this.data});
  final MediaQueryData data;
  @override
  Widget build(BuildContext context) {
    final media = data;
    return SingleChildScrollView(
      child: KitDataTable({
        'size.width': media.size.width,
        'size.height': media.size.height,
        'devicePixelRatio': media.devicePixelRatio,
        'orientation': media.orientation.name,
        'textScaler (14pt)': media.textScaler.scale(14),
        'platformBrightness': media.platformBrightness.name,
        'accessibleNavigation': media.accessibleNavigation,
        'disableAnimations': media.disableAnimations,
        for (final (name, insets) in [
          ('padding', media.padding),
          ('viewPadding', media.viewPadding),
          ('viewInsets', media.viewInsets),
        ]) ...{
          '$name.top': insets.top,
          '$name.bottom': insets.bottom,
          '$name.left': insets.left,
          '$name.right': insets.right,
        },
      }),
    );
  }
}
