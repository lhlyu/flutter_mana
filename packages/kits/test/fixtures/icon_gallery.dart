import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_mana_kits/src/icons/plugin_icons.dart';

void main() => runApp(const PluginIconGallery());

class PluginIconGallery extends StatelessWidget {
  const PluginIconGallery({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
    debugShowCheckedModeBanner: false,
    color: const Color(0xFFF7F9FC),
    textStyle: const TextStyle(
      color: Color(0xFF26384D),
      fontFamily: 'Roboto',
      fontSize: 13,
    ),
    builder: (context, child) => ColoredBox(
      color: const Color(0xFFF7F9FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            const Text(
              'MANA / KIT ICONS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const Text('SVG · 64 × 64 · 40 px panel / 24 px compact'),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final icon in PluginIcon.values)
                  Container(
                    width: 176,
                    height: 164,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      border: Border.all(color: const Color(0xFFE7ECF3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.string(icon.svg, width: 64, height: 64),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 12,
                          children: [
                            SvgPicture.string(icon.svg, width: 40, height: 40),
                            SvgPicture.string(icon.svg, width: 24, height: 24),
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
  );
}
