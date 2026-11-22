import 'dart:async';

import 'package:flutter/widgets.dart';

import '../i18n/kit_localizations.dart';
import 'kit_style.dart';
import 'kit_button.dart';
import 'kit_selection.dart';

class KitScaffold extends StatelessWidget {
  const KitScaffold({super.key, this.header, required this.body, this.footer});
  final Widget? header;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      Widget chrome(Widget child) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight * .4),
        child: SingleChildScrollView(child: child),
      );
      return Column(
        crossAxisAlignment: .stretch,
        children: [
          if (header case final header?) chrome(header),
          Expanded(child: body),
          if (footer case final footer?) chrome(footer),
        ],
      );
    },
  );
}

class KitDivider extends StatelessWidget {
  const KitDivider({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 1,
    width: double.infinity,
    child: ColoredBox(color: KitStyle.border),
  );
}

class KitSection extends StatelessWidget {
  const KitSection(this.title, {super.key, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(12),
    child: Column(
      crossAxisAlignment: .stretch,
      spacing: 8,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: .bold,
            color: KitStyle.text,
          ),
        ),
        child,
      ],
    ),
  );
}

class KitDataTable extends StatelessWidget {
  const KitDataTable(this.data, {super.key});
  final Map<String, Object?> data;
  @override
  Widget build(BuildContext context) => KitSelection(
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final entry in data.entries)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: KitStyle.border)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final key = Text(
                  entry.key,
                  style: const TextStyle(fontWeight: .w600, fontSize: 12),
                );
                final value = Text(
                  '${entry.value ?? '—'}',
                  style: const TextStyle(fontSize: 12),
                );
                return Padding(
                  padding: const .all(10),
                  child:
                      constraints.maxWidth <
                          300 *
                              (MediaQuery.textScalerOf(context).scale(12) / 12)
                                  .clamp(1, 2)
                      ? Column(
                          crossAxisAlignment: .start,
                          spacing: 4,
                          children: [key, value],
                        )
                      : Row(
                          crossAxisAlignment: .start,
                          spacing: 12,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * .35,
                              child: key,
                            ),
                            Expanded(child: value),
                          ],
                        ),
                );
              },
            ),
          ),
      ],
    ),
  );
}

class KitCode extends StatelessWidget {
  const KitCode(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const .all(12),
    color: KitStyle.subtle,
    child: KitSelection(child: Text(text, style: KitStyle.code)),
  );
}

class KitMessage extends StatelessWidget {
  const KitMessage(this.message, {super.key, this.onRetry, this.error = false});
  final String message;
  final FutureOr<void> Function()? onRetry;
  final bool error;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const .all(16),
      child: Column(
        mainAxisSize: .min,
        spacing: 8,
        children: [
          Text(
            message,
            textAlign: .center,
            style: TextStyle(color: error ? KitStyle.danger : KitStyle.muted),
          ),
          if (onRetry != null)
            KitButton(
              label: kitText(context, 'common.retry'),
              icon: .refresh,
              onPressed: onRetry,
            ),
        ],
      ),
    ),
  );
}

class KitDetail extends StatelessWidget {
  const KitDetail({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.trailing,
  });
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: KitStyle.surface,
    child: KitScaffold(
      header: Column(
        mainAxisSize: .min,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 4),
            child: Row(
              children: [
                KitButton(
                  label: kitText(context, 'common.back'),
                  icon: .back,
                  iconOnly: true,
                  onPressed: onClose,
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontWeight: .bold),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const KitDivider(),
        ],
      ),
      body: child,
    ),
  );
}
