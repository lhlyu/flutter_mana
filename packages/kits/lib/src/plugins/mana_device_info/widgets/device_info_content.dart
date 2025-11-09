import 'package:flutter/material.dart';

import '../utils/get_device_info.dart';

class DeviceInfoContent extends StatelessWidget {
  const DeviceInfoContent({super.key});

  static const _borderSide = BorderSide(width: 1, color: Color(0xFFE0E0E0));

  static const _tableBorder = TableBorder(
    top: _borderSide,
    bottom: _borderSide,
    horizontalInside: _borderSide,
    verticalInside: _borderSide,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getDeviceInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        return SelectionArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Table(
              border: _tableBorder,
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              children:
                  data.entries
                      .map(
                        (e) => TableRow(
                          children: [
                            _Cell(e.key, bold: true),
                            _Cell('${e.value}'),
                          ],
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
