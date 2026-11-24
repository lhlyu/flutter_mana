import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import 'shared_preferences_viewer_content.dart';

class SharedPreferencesViewer extends StatefulWidget {
  const SharedPreferencesViewer({super.key, required this.name});

  final String name;

  @override
  State<SharedPreferencesViewer> createState() =>
      _SharedPreferencesViewerState();
}

class _SharedPreferencesViewerState extends State<SharedPreferencesViewer> {
  final _statistics = ValueNotifier<AsyncSnapshot<int>>(
    const AsyncSnapshot.waiting(),
  );

  @override
  void dispose() {
    _statistics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitWindow(
    name: widget.name,
    initialWidth: double.infinity,
    position: .bottom,
    drag: false,
    showBarrier: false,
    content: SharedPreferencesViewerContent(
      onStatisticsChanged: (snapshot) => _statistics.value = snapshot,
    ),
    setting: SingleChildScrollView(
      child: ValueListenableBuilder<AsyncSnapshot<int>>(
        valueListenable: _statistics,
        builder: (context, snapshot, _) {
          if (snapshot.hasError) {
            return KitMessage('${snapshot.error}', error: true);
          }
          if (!snapshot.hasData) {
            return KitMessage(kitText(context, 'common.loading'));
          }
          return KitDataStatistics(
            countLabel: kitText(context, 'statistics.preferences'),
            count: snapshot.requireData,
          );
        },
      ),
    ),
  );
}
