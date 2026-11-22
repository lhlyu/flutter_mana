import 'package:material_ui/material_ui.dart';

import 'demo_session.dart';

class SecondaryPage extends StatefulWidget {
  const SecondaryPage({super.key, required this.session});

  final DemoSession session;

  @override
  State<SecondaryPage> createState() => _SecondaryPageState();
}

class _SecondaryPageState extends State<SecondaryPage> {
  int count = 0;

  String t(String en, String zh) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      key: const Key('secondary-page'),
      appBar: AppBar(
        title: Text(
          t('mana / secondary', 'mana / 副页'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t(
                    'This page shares the debug controller and collectors with '
                        'the home page. Open a tool, switch pages, and check '
                        'that its state and collected data are preserved.',
                    '此页面与主页共用调试控制器和采集器。打开工具后切换页面，'
                        '检查工具状态、网络请求及日志是否保留。',
                  ),
                ),
                const SizedBox(height: 20),
                ListenableBuilder(
                  listenable: session,
                  builder: (context, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final scenario in ['GET', 'POST', '404', 'Timeout'])
                        OutlinedButton(
                          key: Key('secondary-request-$scenario'),
                          onPressed: session.busy
                              ? null
                              : () => session.send(scenario),
                          child: Text(scenario),
                        ),
                      OutlinedButton(
                        key: const Key('secondary-generate-logs'),
                        onPressed: session.writeLogs,
                        child: Text(t('Generate logs', '生成日志')),
                      ),
                      ListenableBuilder(
                        listenable: session.controller,
                        builder: (context, _) => OutlinedButton(
                          key: const Key('secondary-toggle-overlay'),
                          onPressed: () => session.controller.toggleOverlay(),
                          child: Text(
                            session.controller.state.overlayVisible
                                ? t('Hide debug overlay', '隐藏调试层')
                                : t('Show debug overlay', '显示调试层'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListenableBuilder(
                  listenable: session,
                  builder: (context, _) => session.busy
                      ? const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('secondary-input'),
                  decoration: InputDecoration(
                    labelText: t('Secondary page input', '副页输入框'),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('secondary-counter'),
                  onPressed: () => setState(() => count++),
                  child: Text(t('Count: $count', '计数：$count')),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  key: const Key('back-to-home'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(t('Back to home', '返回主页')),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'Back closes an expanded debug tool or panel first. '
                        'Press again to return home.',
                    '返回操作会优先收起展开的调试工具或面板，再次返回即可回到主页。',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
