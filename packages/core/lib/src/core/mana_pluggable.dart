import 'package:flutter/widgets.dart';

/// Defines the basic behavior and properties of a pluggable component (plugin).
///
/// 定义了一个插件的基本行为和属性。
abstract class ManaPluggable {
  /// The unique identifier name for the plugin.
  ///
  /// 插件的唯一标识名。
  String get name;

  /// Returns the localized display name for the plugin.
  /// This supports internationalization.
  ///
  /// 插件在界面上显示的名字，支持国际化。
  String getLocalizedDisplayName(Locale locale);

  /// Called when the plugin is triggered.
  /// This method should contain the plugin's main logic.
  ///
  /// 当插件被触发时调用的方法，执行主要逻辑。
  void onTrigger() {}

  /// Optionally builds a widget to display the plugin's content within the UI.
  /// Returns `null` if the plugin does not have a visual component.
  ///
  /// 可选地构建一个 Widget，用于在界面中展示该插件的内容。
  /// 如果插件没有可视化组件，则返回 `null`。
  Widget? buildWidget(BuildContext? context);

  /// Returns the [ImageProvider] for the plugin's icon, used for displaying the plugin's visual representation.
  ///
  /// 获取插件图标的 [ImageProvider]，用于展示插件图标。
  ImageProvider get iconImageProvider;

  /// Async initialization for the plugin.
  ///
  /// 插件的异步初始化方法
  Future<void> initialize() async {}

  /// Indicates whether the plugin is supported on the current platform or environment.
  ///
  /// 指示当前插件是否支持在当前平台或环境启用。
  bool get isSupported => true;
}
