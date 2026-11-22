import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mana/flutter_mana_widgets.dart';

import '../i18n/kit_localizations.dart';
import 'kit_button.dart';
import 'kit_icons.dart';
import 'kit_layout.dart';
import 'kit_selection.dart';
import 'kit_style.dart';

/// A single scroll surface keeps summaries and actions reachable in short windows.
class KitInfoPage extends StatelessWidget {
  const KitInfoPage({
    super.key,
    required this.title,
    required this.headline,
    this.subtitle,
    required this.data,
    required this.children,
  });

  final String title;
  final String headline;
  final String? subtitle;
  final Map<String, Object?> data;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => KitScaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KitStyle.subtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: KitSelection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: KitStyle.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: KitStyle.text,
                        ),
                      ),
                      if (subtitle case final subtitle?)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: KitStyle.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ...children,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _InfoCopyButton(
                  text: JsonEncoder.withIndent(
                    '  ',
                    (value) => value.toString(),
                  ).convert(data),
                  label: kitText(context, 'info.copy_all'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class KitInfoSection extends StatefulWidget {
  const KitInfoSection({
    super.key,
    required this.title,
    required this.child,
    this.collapsible = false,
  });

  final String title;
  final Widget child;
  final bool collapsible;

  @override
  State<KitInfoSection> createState() => _KitInfoSectionState();
}

class _KitInfoSectionState extends State<KitInfoSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final title = Semantics(
      header: true,
      child: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: KitStyle.accent,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.collapsible)
          Semantics(
            expanded: _expanded,
            child: ManaButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: title),
                  RotatedBox(
                    quarterTurns: _expanded ? 2 : 0,
                    child: const KitGlyph(KitIcon.chevronDown),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(padding: const EdgeInsets.only(bottom: 4), child: title),
        if (!widget.collapsible || _expanded) KitSelection(child: widget.child),
      ],
    );
  }
}

/// Raw platform maps remain inspectable without squeezing nested objects into a row.
class KitInfoFields extends StatelessWidget {
  const KitInfoFields(this.data, {super.key});
  final Map<String, Object?> data;

  Iterable<Widget> _fields(
    Map<Object?, Object?> values, [
    String prefix = '',
  ]) sync* {
    for (final entry in values.entries) {
      final label = '$prefix${entry.key}';
      if (entry.value case final Map value when value.isNotEmpty) {
        yield* _fields(value, '$label.');
      } else {
        yield KitInfoField(label: label, value: entry.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _fields(data).toList(),
  );
}

class KitInfoField extends StatelessWidget {
  const KitInfoField({
    super.key,
    required this.label,
    required this.value,
    this.copyText,
  });
  final String label;
  final Object? value;
  final String? copyText;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: KitStyle.border)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidget = Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: KitStyle.muted,
            ),
          );
          final valueWidget = Text(
            infoValue(value, context),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: KitStyle.text,
            ),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              valueWidget,
              if (copyText case final text?)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _InfoCopyButton(text: text),
                ),
            ],
          );
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          if (constraints.maxWidth < 440 * scale) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [labelWidget, content],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              SizedBox(width: constraints.maxWidth * .32, child: labelWidget),
              Expanded(child: content),
            ],
          );
        },
      ),
    ),
  );
}

String infoValue(Object? value, BuildContext context) => switch (value) {
  null || '' => '—',
  bool value => kitText(context, value ? 'info.yes' : 'info.no'),
  Iterable value =>
    value.isEmpty
        ? '—'
        : value.map((item) => infoValue(item, context)).join('\n'),
  Map value when value.isEmpty => '—',
  _ => '$value',
};

class _InfoCopyButton extends StatefulWidget {
  const _InfoCopyButton({required this.text, this.label});
  final String text;
  final String? label;

  @override
  State<_InfoCopyButton> createState() => _InfoCopyButtonState();
}

class _InfoCopyButtonState extends State<_InfoCopyButton> {
  bool _copied = false;

  @override
  void didUpdateWidget(covariant _InfoCopyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _copied = false;
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 44),
    child: KitButton(
      label: _copied
          ? kitText(context, 'info.copied')
          : widget.label ?? kitText(context, 'common.copy'),
      icon: _copied ? KitIcon.check : KitIcon.copy,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        if (mounted) setState(() => _copied = true);
      },
    ),
  );
}
