import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

class ScreenInfoContent extends StatelessWidget {
  const ScreenInfoContent({super.key, required this.data});
  final MediaQueryData data;

  @override
  Widget build(BuildContext context) {
    String text(String key) => kitText(context, 'screen.$key');
    final insets = [
      ('padding', data.padding),
      ('viewPadding', data.viewPadding),
      ('viewInsets', data.viewInsets),
    ];
    return KitInfoPage(
      title: text('title'),
      headline: '${_number(data.size.width)} × ${_number(data.size.height)}',
      subtitle: 'logical px · ${text(data.orientation.name)}',
      data: {
        'size.width': data.size.width,
        'size.height': data.size.height,
        'devicePixelRatio': data.devicePixelRatio,
        'orientation': data.orientation.name,
        'textScaler (14pt)': data.textScaler.scale(14),
        'platformBrightness': data.platformBrightness.name,
        'accessibleNavigation': data.accessibleNavigation,
        'disableAnimations': data.disableAnimations,
        for (final (name, value) in insets) ...{
          '$name.top': value.top,
          '$name.right': value.right,
          '$name.bottom': value.bottom,
          '$name.left': value.left,
        },
      },
      children: [
        KitInfoSection(
          title: text('viewport'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KitInfoField(
                label: text('pixel_ratio'),
                value: '${_number(data.devicePixelRatio)}×',
              ),
              KitInfoField(
                label: text('pixel_size'),
                value:
                    '${_number(data.size.width * data.devicePixelRatio)} × '
                    '${_number(data.size.height * data.devicePixelRatio)} px',
              ),
            ],
          ),
        ),
        KitInfoSection(
          title: text('insets'),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
              if (constraints.maxWidth >= 560 * scale) {
                return Table(
                  columnWidths: const {0: FlexColumnWidth(2)},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: KitStyle.border),
                  ),
                  children: [
                    TableRow(
                      children: [
                        _cell('logical px', muted: true),
                        for (final side in ['top', 'right', 'bottom', 'left'])
                          _cell(text(side), muted: true),
                      ],
                    ),
                    for (final (name, value) in insets)
                      TableRow(
                        children: [
                          _cell(text(name)),
                          for (final number in [
                            value.top,
                            value.right,
                            value.bottom,
                            value.left,
                          ])
                            _cell(_number(number)),
                        ],
                      ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  for (final (name, value) in insets)
                    _InsetsGroup(name: name, insets: value),
                ],
              );
            },
          ),
        ),
        KitInfoSection(
          title: text('appearance'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KitInfoField(
                label: text('brightness'),
                value: text(data.platformBrightness.name),
              ),
              KitInfoField(
                label: text('text_scaling'),
                value: '14 → ${_number(data.textScaler.scale(14))} logical px',
              ),
              KitInfoField(
                label: text('navigation'),
                value: data.accessibleNavigation,
              ),
              KitInfoField(
                label: text('animations'),
                value: data.disableAnimations,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String value, {bool muted = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    child: Text(
      value,
      style: TextStyle(
        fontSize: muted ? 12 : 14,
        height: 1.5,
        color: muted ? KitStyle.muted : KitStyle.text,
      ),
    ),
  );
}

class _InsetsGroup extends StatelessWidget {
  const _InsetsGroup({required this.name, required this.insets});
  final String name;
  final EdgeInsets insets;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: KitStyle.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text(
          '${kitText(context, 'screen.$name')} · logical px',
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: KitStyle.muted,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final columns = constraints.maxWidth >= 200 * scale ? 2 : 1;
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final (side, value) in [
                  ('top', insets.top),
                  ('right', insets.right),
                  ('bottom', insets.bottom),
                  ('left', insets.left),
                ])
                  SizedBox(
                    width:
                        (constraints.maxWidth - 16 * (columns - 1)) / columns,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${kitText(context, 'screen.$side')}  ',
                            style: const TextStyle(
                              color: KitStyle.muted,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(text: _number(value)),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: KitStyle.text,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

String _number(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
