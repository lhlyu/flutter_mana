import 'package:flutter_mana/flutter_mana.dart';
import 'package:material_ui/material_ui.dart';

import 'demo_session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, this.session});
  final DemoSession? session;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final session = widget.session ?? DemoSession();
  late final observer = ManaNavigatorObserver(session.controller);
  Locale locale = const Locale('en');
  bool dark = false;

  @override
  void dispose() {
    observer.dispose();
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Mana Example',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('zh')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    navigatorObservers: [observer],
    builder: (context, child) => ManaWidget.builder(
      controller: session.controller,
      child: child ?? const SizedBox.shrink(),
    ),
    home: _ExamplePage(
      session: session,
      locale: locale,
      onLocaleChanged: (value) => setState(() => locale = value),
      onThemeChanged: () => setState(() => dark = !dark),
    ),
  );
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final foreground = dark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);
  final background = dark ? const Color(0xFF09090B) : Colors.white;
  final border = dark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      ).copyWith(
        primary: foreground,
        onPrimary: background,
        surface: background,
        onSurface: foreground,
        outline: border,
        secondaryContainer: border,
        onSecondaryContainer: foreground,
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    dividerColor: border,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}

class _ExamplePage extends StatefulWidget {
  const _ExamplePage({
    required this.session,
    required this.locale,
    required this.onLocaleChanged,
    required this.onThemeChanged,
  });
  final DemoSession session;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onThemeChanged;

  @override
  State<_ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<_ExamplePage>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  bool animate = false;
  double radius = 8;
  String dropdownValue = 'default';

  String t(String en, String zh) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  Future<void> seedPreferences() async {
    try {
      await widget.session.seedPreferences();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('Saved.', '已写入。'))));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('Storage error', '存储失败')}: $error')),
        );
      }
    }
  }

  Future<void> openSampleDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('sample-dialog'),
        title: Text(t('Sample dialog', '弹窗示例')),
        content: Text(
          t(
            'Try inspecting this dialog with the Mana tools.',
            '试试使用 Mana 工具检查这个弹窗。',
          ),
        ),
        actions: [
          TextButton(
            key: const Key('dialog-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('Cancel', '取消')),
          ),
          FilledButton(
            key: const Key('dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('Confirm', '确认')),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('Dialog confirmed.', '已确认弹窗。'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'mana / example',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          SegmentedButton<Locale>(
            segments: const [
              ButtonSegment(value: Locale('en'), label: Text('EN')),
              ButtonSegment(value: Locale('zh'), label: Text('中文')),
            ],
            selected: {widget.locale},
            showSelectedIcon: false,
            onSelectionChanged: (value) => widget.onLocaleChanged(value.single),
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          IconButton(
            onPressed: widget.onThemeChanged,
            tooltip: t('Toggle theme', '切换主题'),
            icon: const Icon(Icons.contrast_rounded, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final scenario in ['GET', 'POST', '404', 'Timeout'])
                        OutlinedButton(
                          key: Key('request-$scenario'),
                          onPressed: session.busy
                              ? null
                              : () => session.send(scenario),
                          child: Text(scenario),
                        ),
                      ListenableBuilder(
                        listenable: session.controller,
                        builder: (context, _) => OutlinedButton(
                          key: const Key('toggle-overlay'),
                          onPressed: () => session.controller.toggleOverlay(),
                          child: Text(
                            session.controller.state.overlayVisible
                                ? t('Hide debug overlay', '隐藏调试层')
                                : t('Show debug overlay', '显示调试层'),
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: session.writeLogs,
                        child: Text(t('Generate logs', '生成日志')),
                      ),
                      OutlinedButton(
                        onPressed: seedPreferences,
                        child: Text(t('Seed preferences', '写入存储')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (session.busy) const LinearProgressIndicator(minHeight: 2),
                  Row(
                    children: [
                      for (final color in [
                        0xFF18181B,
                        0xFF52525B,
                        0xFFA1A1AA,
                        0xFFE4E4E7,
                      ])
                        Expanded(
                          child: Container(height: 32, color: Color(color)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const Key('sample-input'),
                    decoration: InputDecoration(
                      labelText: t('Sample input', '输入示例'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton(
                        key: const Key('open-dialog'),
                        onPressed: openSampleDialog,
                        child: Text(t('Open dialog', '打开弹窗')),
                      ),
                      DropdownButton<String>(
                        key: const Key('sample-dropdown'),
                        value: dropdownValue,
                        borderRadius: BorderRadius.circular(6),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => dropdownValue = value);
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'default',
                            child: Text(t('Default', '默认')),
                          ),
                          DropdownMenuItem(
                            value: 'compact',
                            child: Text(t('Compact', '紧凑')),
                          ),
                          DropdownMenuItem(
                            value: 'comfortable',
                            child: Text(t('Comfortable', '舒适')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: RotationTransition(
                      turns: animation,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        t('Radius', '圆角'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: radius,
                          min: 0,
                          max: 24,
                          onChanged: (value) => setState(() => radius = value),
                        ),
                      ),
                      Text(
                        '${radius.round()} px',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t('Animation', '动画'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: animate,
                    onChanged: (value) => setState(() {
                      animate = value;
                      if (value) {
                        animation.repeat();
                      } else {
                        animation.stop();
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
