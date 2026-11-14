import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana.dart';

abstract class BuiltinKit extends ManaPluggable {
  BuiltinKit({
    required this.name,
    required this.title,
    required this.chineseTitle,
    required this.iconImageProvider,
  });
  @override
  final String name;
  final String title;
  final String chineseTitle;
  @override
  final ImageProvider iconImageProvider;
  @override
  String getLocalizedDisplayName(Locale locale) =>
      locale.languageCode == 'zh' ? chineseTitle : title;
}
