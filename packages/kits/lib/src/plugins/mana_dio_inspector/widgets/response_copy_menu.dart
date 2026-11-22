import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';
import '../request_format.dart';

class ResponseCopyMenu extends StatefulWidget {
  const ResponseCopyMenu({super.key, required this.response});

  final Response<dynamic> response;

  @override
  State<ResponseCopyMenu> createState() => _ResponseCopyMenuState();
}

class _ResponseCopyMenuState extends State<ResponseCopyMenu> {
  final _controller = MenuController();
  final _anchorFocus = FocusNode();
  final _menuFocus = FocusScopeNode();

  @override
  void dispose() {
    _anchorFocus.dispose();
    _menuFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moreActions = kitText(context, 'common.more_actions');
    final copy = kitText(context, 'common.copy');
    final request = widget.response.requestOptions;
    return RawMenuAnchor(
      controller: _controller,
      childFocusNode: _anchorFocus,
      consumeOutsideTaps: true,
      onOpen: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_controller.isOpen) return;
          _menuFocus.requestFocus();
          _menuFocus.nextFocus();
        });
      },
      builder: (context, controller, _) => Semantics(
        label: moreActions,
        expanded: controller.isOpen,
        child: ManaButton(
          focusNode: _anchorFocus,
          tooltip: moreActions,
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: const KitGlyph(.more),
        ),
      ),
      overlayBuilder: (context, info) => CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: info.anchorRect.topCenter,
          anchorBelow: info.anchorRect.bottomCenter,
        ),
        child: TapRegion(
          groupId: info.tapRegionGroupId,
          onTapOutside: (_) => _controller.close(),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: moreActions,
            role: .menu,
            child: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
                SingleActivator(LogicalKeyboardKey.arrowDown):
                    NextFocusIntent(),
                SingleActivator(LogicalKeyboardKey.arrowUp):
                    PreviousFocusIntent(),
              },
              child: Actions(
                actions: {
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (_) {
                      _controller.close();
                      return null;
                    },
                  ),
                },
                child: FocusScope(
                  node: _menuFocus,
                  child: Container(
                    width: 220,
                    constraints: BoxConstraints(
                      maxHeight: info.overlaySize.height * .6,
                    ),
                    padding: const .all(4),
                    decoration: BoxDecoration(
                      color: KitStyle.surface,
                      border: Border.all(color: KitStyle.border),
                      borderRadius: .circular(8),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 8),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .stretch,
                        children: [
                          for (final (label, value) in [
                            ('URL', () => request.uri.toString()),
                            ('cURL', () => formatCurl(request)),
                            ('HTTP', () => formatHttp(request)),
                            (
                              kitText(context, 'dio_inspector.response'),
                              () => formatBody(widget.response.data),
                            ),
                          ])
                            Align(
                              alignment: .centerStart,
                              child: KitButton(
                                label: '$copy $label',
                                icon: .copy,
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: value()),
                                  );
                                  if (mounted) _controller.close();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
