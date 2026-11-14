import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../icons/plugin_icons.dart';

abstract class BuiltinKit extends ManaPluggable {
  BuiltinKit({
    required this.name,
    required this.title,
    required this.chineseTitle,
    required this.icon,
  });
  @override
  final String name;
  final String title;
  final String chineseTitle;
  final PluginIcon icon;

  @override
  ImageProvider get iconImageProvider => PluginIconImage(icon);

  @override
  Widget buildIcon(BuildContext context, {double size = 40}) =>
      SvgPicture.string(
        icon.svg,
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
  @override
  String getLocalizedDisplayName(Locale locale) =>
      locale.languageCode == 'zh' ? chineseTitle : title;
}
