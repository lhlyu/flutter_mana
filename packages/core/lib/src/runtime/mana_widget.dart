import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../widgets/mana_overlay.dart';
import '../widgets/mana_style.dart';
import 'mana_controller.dart';
import 'mana_pluggable.dart';
import 'mana_scope.dart';

/// Standalone host; use .builder inside an existing app.
class ManaWidget extends StatefulWidget {
  final Widget child;
  final ManaController? controller;
  final List<ManaPluggable> plugins;
  final bool enable;
  final TransitionBuilder? overlayBuilder;
  final BackButtonDispatcher? backButtonDispatcher;
  final bool _embedded;

  const ManaWidget({
    super.key,
    required this.child,
    this.controller,
    this.plugins = const [],
    this.enable = true,
    this.overlayBuilder,
  }) : _embedded = false,
       backButtonDispatcher = null;

  /// Router hosts must pass their BackButtonDispatcher.
  const ManaWidget.builder({
    super.key,
    required this.child,
    this.controller,
    this.plugins = const [],
    this.enable = true,
    this.overlayBuilder,
    this.backButtonDispatcher,
  }) : _embedded = true;

  @override
  State<ManaWidget> createState() => _ManaWidgetState();
}

class _ManaWidgetState extends State<ManaWidget> with WidgetsBindingObserver {
  static final _supportedLocales = [
    const Locale('en'),
    for (final language in kWidgetsSupportedLanguages)
      if (language != 'en') Locale(language),
  ];
  late ManaController _controller;
  late bool _ownsController;
  ChildBackButtonDispatcher? _backDispatcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachController();
    _configureBackDispatcher();
  }

  void _attachController() {
    if (widget.controller != null && widget.plugins.isNotEmpty) {
      throw ArgumentError(
        'Pass either controller or initial plugins, not both.',
      );
    }
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ManaController(plugins: widget.plugins);
    _controller.attach(this);
    if (widget.enable) _start();
  }

  void _start() {
    // initialize() reports errors through the controller.
    unawaited(_controller.initialize().catchError((Object _) {}));
  }

  void _detachController() {
    _controller.detach(this);
    if (_ownsController) unawaited(_controller.close());
  }

  void _configureBackDispatcher() {
    _backDispatcher?.removeCallback(_onBack);
    final child = widget.backButtonDispatcher
        ?.createChildBackButtonDispatcher();
    _backDispatcher = child;
    child?.addCallback(_onBack);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && child != null && identical(child, _backDispatcher)) {
        child.takePriority();
      }
    });
  }

  Future<bool> _onBack() async => widget.enable && _controller.handleBack();

  @override
  Future<bool> didPopRoute() async {
    if (widget._embedded) return false;
    return _onBack();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (!widget._embedded && widget.enable) setState(() {});
  }

  @override
  void didUpdateWidget(ManaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController();
    } else if (widget.enable && !oldWidget.enable) {
      _start();
    }
    if (oldWidget.backButtonDispatcher != widget.backButtonDispatcher) {
      _configureBackDispatcher();
    }
  }

  @override
  void dispose() {
    _backDispatcher?.removeCallback(_onBack);
    WidgetsBinding.instance.removeObserver(this);
    _detachController();
    super.dispose();
  }

  Widget _buildHost() => ManaScope(
    key: ObjectKey(_controller),
    controller: _controller,
    child: Stack(
      fit: .expand,
      children: [
        RepaintBoundary(key: _controller.rootKey, child: widget.child),
        Positioned.fill(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (!_controller.isReady) return const SizedBox.shrink();
              const overlay = ManaOverlay();
              final visible = _controller.state.overlayVisible;
              return Offstage(
                offstage: !visible,
                child: TickerMode(
                  enabled: visible,
                  child: ExcludeFocus(
                    excluding: !visible,
                    child: LayoutBuilder(
                      builder: (context, constraints) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(size: constraints.biggest),
                        child: Builder(
                          builder: (context) => Overlay.wrap(
                            child: DefaultTextStyle(
                              style: ManaStyle.textStyle,
                              child: IconTheme(
                                data: const IconThemeData(
                                  color: ManaStyle.text,
                                  size: 24,
                                ),
                                child:
                                    widget.overlayBuilder?.call(
                                      context,
                                      overlay,
                                    ) ??
                                    overlay,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.enable) return widget.child;
    if (widget._embedded) return _buildHost();
    final locales = View.of(context).platformDispatcher.locales;
    return WidgetsApp(
      color: ManaStyle.surface,
      textStyle: ManaStyle.textStyle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [GlobalWidgetsLocalizations.delegate],
      locale: locales.firstOrNull ?? const Locale('en'),
      supportedLocales: _supportedLocales,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: .zero,
        reverseTransitionDuration: .zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
      ),
      home: _buildHost(),
    );
  }
}
