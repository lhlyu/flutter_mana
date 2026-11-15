import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_mana_kits/src/icons/plugin_icons.dart';

void main() => runApp(const PluginIconGallery());

class PluginIconGallery extends StatelessWidget {
  const PluginIconGallery({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
    debugShowCheckedModeBanner: false,
    color: const Color(0xFFFFFFFF),
    textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
    builder: (context, child) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final dark in [false, true])
            ColoredBox(
              color: dark ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: dark
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFF26384D),
                  fontFamily: 'Roboto',
                  fontSize: 13,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: [
                      Text(
                        'MANA / KIT ICONS / ${dark ? 'DARK' : 'LIGHT'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Transparent SVG · 64 px / 40 px panel / 24 px compact',
                      ),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final icon in PluginIcon.values)
                            SizedBox(
                              width: 176,
                              height: 140,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SvgPicture.string(
                                    icon.svg,
                                    width: 64,
                                    height: 64,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 12,
                                    children: [
                                      SvgPicture.string(
                                        icon.svg,
                                        width: 40,
                                        height: 40,
                                      ),
                                      SvgPicture.string(
                                        icon.svg,
                                        width: 24,
                                        height: 24,
                                      ),
                                    ],
                                  ),
                                  Text(icon.name),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
