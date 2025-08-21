import 'package:flutter_mana/flutter_mana.dart';

mixin I18nMixin {
  static const _strings = {
    // Align Ruler
    'align_ruler.tip': ['Snap to nearest widget edge on release', '开启后松手将会自动吸附至最近部件边缘'],

    // Color Sucker
    'color_sucker.magnification': ['Magnification', '放大率'],

    // Dio Inspector
    'dio_inspector.filter_keywords': ['filter keywords...', '筛选字词...'],
    'dio_inspector.detail': ['Detail', '详情'],
    'dio_inspector.request': ['Request', '请求'],
    'dio_inspector.response': ['Response', '响应'],
    'dio_inspector.request_details': ['Request Details', '请求详情'],
    'dio_inspector.request_header': ['Request Header', '请求头'],
    'dio_inspector.request_body': ['Request Body', '请求体'],
    'dio_inspector.response_header': ['Response Header', '响应头'],
    'dio_inspector.response_body': ['Response Body', '响应体'],

    // Fps Monitor
    'fps_monitor.tip': ['Web is not supported!', 'Web端不支持！'],

    // Log Viewer
    'log_viewer.filter_keywords': ['filter keywords...', '筛选字词...'],
    'log_viewer.verbose_logs': ['Verbose Logs', '详细日志'],

    // Memory Info
    'memory_info.vm_info': ['VM Info', 'VM 信息'],
    'memory_info.version': ['Version:', '版本:'],
    'memory_info.memory_info': ['Memory Info', '内存信息'],
    'memory_info.hide_private_classes': ['hide private classes', '隐藏私有类'],
    'memory_info.current_app': ['Current App', '当前应用'],
    'memory_info.total': ['Total:', '总数:'],
    'memory_info.size': ['Size', '大小'],
    'memory_info.number': ['Number', '数量'],
    'memory_info.class_name': ['Class', '类名'],
    'memory_info.class_no_detail': [
      'The object is a Sentinel or lacks detailed information',
      '该对象是一个 Sentinel 或没有详细信息'
    ],
    'memory_info.location': ['Location:', '位置:'],
    'memory_info.property': ['Property:', '属性:'],
    'memory_info.function': ['Function:', '方法:'],

    // Shared Preferences Viewer
    'shared_preferences_viewer.filter_keywords': ['filter keywords...', '筛选字词...'],
    'shared_preferences_viewer.type': ['Type', '类型'],
    'shared_preferences_viewer.key': ['Key', '键'],
    'shared_preferences_viewer.key_required': ['Key Required', '键必填'],
    'shared_preferences_viewer.value': ['Value', '值'],
    'shared_preferences_viewer.value_required': ['Value Required', '值必填'],
    'shared_preferences_viewer.value_must_double': ['Value Must Double', '值必须是Double类型'],
    'shared_preferences_viewer.value_must_bool': ['Value Must Bool', '值必须是Bool类型'],
    'shared_preferences_viewer.value_must_int': ['Value Must Int', '值必须是Int类型'],
    'shared_preferences_viewer.value_must_list_of_string': ['Value Must List<String>', '值必须是List<String>类型'],
    'shared_preferences_viewer.save': ['Save', '保存'],
    'shared_preferences_viewer.cancel': ['Cancel', '取消'],

    // Widget Info Inspector
    'widget_info_inspector.tip': ['Switch drawing mode', '切换绘制模式'],

    // Gird
    'grid.show_numbers': ['Show Numbers', '显示坐标'],
    'grid.gap': ['Gap', '间隔'],

    // Visual Helper
    'visual_helper.animate_speed': ['Animate Speed', '动画倍速'],
    'visual_helper.layout_bounds': ['Layout Bounds', '布局边界'],
    'visual_helper.show_widget_borders': ['show widget borders', '显示每个组件边框'],
    'visual_helper.repaint_highlight': ['Repaint highlight', '重绘高亮'],
    'visual_helper.frame_repaint_highlight': ['frame repaint highlight', '高亮每帧重绘区域'],
    'visual_helper.invert_oversized_images': ['Invert Oversized Images', '大图反色'],
    'visual_helper.invert_oversized_images_label': ['invert oversized images', '超大图片反色提示'],
  };

  static final _language = manaLocale.languageCode;

  String t(String k, [String defaultValue = '']) {
    final ss = _strings[k];
    if (ss == null) {
      return defaultValue;
    }
    switch (_language) {
      case 'zh':
        return ss[1];
      default:
        return ss[0];
    }
  }
}
