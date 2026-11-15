import 'package:flutter/widgets.dart';

String kitText(BuildContext context, String key) {
  final value = _strings[key];
  if (value == null) return key;
  return Localizations.maybeLocaleOf(context)?.languageCode == 'zh'
      ? value.zh
      : value.en;
}

const _strings = {
  'common.all': (en: 'All', zh: '全部'),
  'common.empty': (en: 'No items', zh: '暂无数据'),
  'common.loading': (en: 'Loading…', zh: '加载中…'),
  'common.working': (en: 'Working…', zh: '处理中…'),
  'common.retry': (en: 'Retry', zh: '重试'),
  'common.refresh': (en: 'Refresh', zh: '刷新'),
  'common.copy': (en: 'Copy', zh: '复制'),
  'common.back': (en: 'Back', zh: '返回'),
  'common.clear': (en: 'Clear', zh: '清空'),
  'common.confirm_clear': (en: 'Clear all preferences', zh: '清空全部偏好'),
  'common.cancel': (en: 'Cancel', zh: '取消'),
  'common.save': (en: 'Save', zh: '保存'),
  'common.add': (en: 'Add', zh: '新增'),
  'common.delete': (en: 'Delete', zh: '删除'),
  'common.search': (en: 'Search', zh: '搜索'),
  'common.top': (en: 'Scroll to top', zh: '滚动到顶部'),
  'common.bottom': (en: 'Scroll to bottom', zh: '滚动到底部'),
  'common.lock': (en: 'Lock auto-scroll', zh: '锁定自动滚动'),
  'common.unlock': (en: 'Unlock auto-scroll', zh: '解锁自动滚动'),
  'common.details': (en: 'Details', zh: '详情'),
  'common.unsupported': (en: 'Unavailable in this build', zh: '当前构建不可用'),
  'align_ruler.snap': (en: 'Snap to widget edges', zh: '吸附部件边缘'),
  'color_sucker.magnification': (en: 'Magnification', zh: '放大率'),
  'dio_inspector.detail': (en: 'Detail', zh: '详情'),
  'dio_inspector.request': (en: 'Request', zh: '请求'),
  'dio_inspector.response': (en: 'Response', zh: '响应'),
  'dio_inspector.request_header': (en: 'Request Header', zh: '请求头'),
  'dio_inspector.request_body': (en: 'Request Body', zh: '请求体'),
  'dio_inspector.response_header': (en: 'Response Header', zh: '响应头'),
  'dio_inspector.response_body': (en: 'Response Body', zh: '响应体'),
  'log_viewer.verbose_logs': (en: 'Verbose Logs', zh: '详细日志'),
  'memory_info.hide_private_classes': (en: 'Hide private classes', zh: '隐藏私有类'),
  'memory_info.size': (en: 'Size', zh: '大小'),
  'memory_info.number': (en: 'Number', zh: '数量'),
  'memory_info.class_name': (en: 'Class', zh: '类名'),
  'memory_info.class_no_detail': (en: 'No class details', zh: '暂无类信息'),
  'memory_info.fields': (en: 'Fields', zh: '字段'),
  'memory_info.functions': (en: 'Methods', zh: '方法'),
  'shared_preferences_viewer.type': (en: 'Type', zh: '数据类型'),
  'shared_preferences_viewer.key': (en: 'Key', zh: '键'),
  'shared_preferences_viewer.value': (en: 'Value', zh: '值'),
  'grid.show_numbers': (en: 'Show Numbers', zh: '显示坐标'),
  'grid.gap': (en: 'Gap', zh: '间隔'),
  'visual_helper.animation_speed': (en: 'Animation speed', zh: '动画速度'),
  'visual_helper.layout_bounds': (en: 'Layout Bounds', zh: '布局边界'),
  'visual_helper.repaint_highlight': (en: 'Repaint highlight', zh: '重绘高亮'),
  'visual_helper.invert_oversized_images': (
    en: 'Invert Oversized Images',
    zh: '大图反色',
  ),
};
