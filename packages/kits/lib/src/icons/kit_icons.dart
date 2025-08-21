import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

/// 方便日后统一改图标
abstract final class KitIcons {
  static const copy = Icons.copy;
  static const copy_success = Icons.check;
  static const search = Icons.search;
  static const more = Icons.more_horiz;
  static const close = Icons.close;
  static const refresh = Icons.refresh;
  static const add = Icons.add;
  static const lock = Icons.lock_outline;
  static const lock_open = Icons.lock_open_outlined;
  static const clear = Icons.delete_outline;
  static const top = Icons.vertical_align_top_outlined;
  static const down = Icons.vertical_align_bottom_outlined;
  static const filter_on = Icons.filter_list_sharp;
  static const filter_off = Icons.filter_list_off_sharp;

  // 升序
  static const sort_asc = Icons.arrow_drop_up;

  // 降序
  static const sort_desc = Icons.arrow_drop_down;

  // 自动
  static const sort_auto = Icons.unfold_more;

  static const eye = Icons.remove_red_eye_outlined;
}
