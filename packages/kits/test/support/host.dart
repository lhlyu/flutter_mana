import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_widgets.dart';

Widget testHost(
  Widget child, {
  TextDirection direction = .ltr,
  double scale = 1,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: Directionality(
    textDirection: direction,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: DefaultTextStyle(style: ManaStyle.textStyle, child: child),
      ),
    ),
  ),
);
