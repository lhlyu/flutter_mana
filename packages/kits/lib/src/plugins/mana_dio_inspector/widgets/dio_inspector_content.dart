import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';

import '../mana_dio_collector.dart';
import 'response_detail.dart';
import 'response_tile.dart';

class DioInspectorContent extends StatefulWidget {
  const DioInspectorContent({super.key});

  @override
  State<DioInspectorContent> createState() => _DioInspectorContentState();
}

class _DioInspectorContentState extends State<DioInspectorContent>
    with SingleTickerProviderStateMixin, I18nMixin {
  late TabController _tabController;

  late final TextEditingController _filterController;
  Timer? _debounceTimer;

  final ScrollController _scrollController = ScrollController();

  final List<String> _tabs = ['All', 'Get', 'Post', 'Put', 'Delete'];

  String _currentTab = 'All';

  /// 是否启用过滤
  bool _filter = false;

  /// 过滤关键字词
  String _filterKeywords = '';

  bool _lock = false;

  List<Response> _filteredData = [];

  /// 当前需要查看的response详情
  Response? _response;

  // 统一的字体大小
  static const double _fontSize = 12.0;

  static final _divider = Divider(height: 1, color: Colors.grey.shade200);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_handleTabSelection);
    _filterController = TextEditingController()..addListener(_onTextChanged);
    ManaDioCollector().addListener(_onDataChanged);
    _onDataChanged();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    ManaDioCollector().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _updateFilteredData(ManaDioCollector().data);
    if (_lock) {
      return;
    }
    _scrollToBottom();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() => _currentTab = _tabs[_tabController.index]);
    _updateFilteredData(ManaDioCollector().data);
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _filterKeywords = _filterController.text);
      _updateFilteredData(ManaDioCollector().data);
    });
  }

  void _updateFilteredData(Iterable<Response> data) {
    final filtered = data.where((d) {
      final matchLevel =
          _currentTab == 'All' ||
          d.requestOptions.method.toLowerCase() == _currentTab.toLowerCase();
      final matchKeyword =
          !_filter ||
          _filterKeywords.isEmpty ||
          (_filter &&
              _filterKeywords.isNotEmpty &&
              d.requestOptions.uri.toString().contains(_filterKeywords));
      return matchLevel && matchKeyword;
    });

    setState(() {
      _filteredData = filtered.toList();
    });
  }

  void _scrollToBottom([bool animate = true]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final offset = _scrollController.position.maxScrollExtent;

      if (animate) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  // 允许/锁住滚动
  void _toggleLock() {
    setState(() {
      _lock = !_lock;
    });
  }

  void _clear() => ManaDioCollector().clear();

  void _toggleFilter() {
    _filter = !_filter;
    setState(() {
      _onDataChanged();
    });
  }

  /// 创建顶部区域
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.transparent,
        dividerHeight: 0,
        isScrollable: false,
        labelStyle: const TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
        ),
        tabs: _tabs.map((tab) => Tab(text: tab, height: 36)).toList(),
      ),
    );
  }

  /// 创建中部区域
  Widget _buildCenter() {
    return Expanded(
      child: ListView.separated(
        controller: _scrollController,
        itemCount: _filteredData.length,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        itemBuilder: (context, index) {
          final d = _filteredData[index];
          return ResponseTile(
            response: d,
            onTap: () {
              setState(() {
                _response = d;
              });
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return _divider;
        },
      ),
    );
  }

  /// 创建底部操作栏
  Widget _buildBottom() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          if (_filter) ...[
            TextField(
              controller: _filterController,
              style: const TextStyle(fontSize: _fontSize),
              decoration: InputDecoration(
                hintText: t('dio_inspector.filter_keywords'),
                hintStyle: TextStyle(
                  fontSize: _fontSize,
                  color: Colors.black54,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
            _divider,
          ],
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const selects = [false, false, false, false, false];

              double buttonWidth = constraints.maxWidth / selects.length;

              return ToggleButtons(
                isSelected: selects,
                renderBorder: false,
                constraints: BoxConstraints(
                  minHeight: 36.0,
                  minWidth: buttonWidth,
                ),
                textStyle: const TextStyle(fontSize: _fontSize),
                onPressed: (int index) {
                  switch (index) {
                    case 0:
                      _clear();
                      return;
                    case 1:
                      _scrollToTop();
                      return;
                    case 2:
                      _scrollToBottom();
                      return;
                    case 3:
                      _toggleLock();
                      break;
                    case 4:
                      _toggleFilter();
                      break;
                  }
                },
                children: [
                  Icon(KitIcons.clear, size: 16),
                  Icon(KitIcons.top, size: 16),
                  Icon(KitIcons.down, size: 16),
                  Icon(_lock ? KitIcons.lock : KitIcons.lock_open, size: 16),
                  Icon(
                    _filter ? KitIcons.filter_off : KitIcons.filter_on,
                    size: 16,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              _divider,
              _buildHeader(),
              _divider,
              _buildCenter(),
              // 底部工具栏
              _divider,
              _buildBottom(),
            ],
          ),
        ),
        if (_response != null)
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: ResponseDetail(
                response: _response!,
                onClose: () {
                  setState(() {
                    _response = null;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
