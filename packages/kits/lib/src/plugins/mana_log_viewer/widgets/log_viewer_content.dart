import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';
import 'package:logger/logger.dart';

import '../mana_log_collector.dart';
import 'log_item_widget.dart';

class LogViewerContent extends StatefulWidget {
  final bool verboseLogs;

  const LogViewerContent({super.key, required this.verboseLogs});

  @override
  State<LogViewerContent> createState() => _LogViewerContentState();
}

class _LogViewerContentState extends State<LogViewerContent>
    with SingleTickerProviderStateMixin, I18nMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late final TextEditingController _filterController;
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabs = ['All', 'Debug', 'Info', 'Warning', 'Error'];

  String _currentTab = 'All';
  bool _filter = false;
  String _filterKeywords = '';

  bool _lock = false;

  List<OutputEvent> _filteredData = [];
  Timer? _debounceTimer;

  static const double _fontSize = 12.0;

  static final _divider = Divider(height: 1, color: Colors.grey.shade200);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)..addListener(_handleTabSelection);
    _filterController = TextEditingController()..addListener(_onTextChanged);
    ManaLogCollector().addListener(_onDataChanged);
    _onDataChanged();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    ManaLogCollector().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _updateFilteredData(ManaLogCollector().data);
    if (_lock) {
      return;
    }
    _scrollToBottom();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() => _currentTab = _tabs[_tabController.index]);
    _updateFilteredData(ManaLogCollector().data);
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _filterKeywords = _filterController.text);
      _updateFilteredData(ManaLogCollector().data);
    });
  }

  void _updateFilteredData(Iterable<OutputEvent> data) {
    final filtered = data.where((d) {
      final matchLevel = _currentTab == 'All' || d.level.name.toLowerCase() == _currentTab.toLowerCase();
      final matchKeyword =
          !_filter ||
          _filterKeywords.isEmpty ||
          (_filter && _filterKeywords.isNotEmpty && d.origin.message.toString().contains(_filterKeywords));
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
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  // 允许/锁住滚动
  void _toggleLock() {
    setState(() {
      _lock = !_lock;
    });
  }

  void _clear() => ManaLogCollector().clear();

  void _toggleFilter() {
    _filter = !_filter;
    setState(() {
      _onDataChanged();
    });
  }

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
        tabs: _tabs.map((tab) => Tab(text: tab, height: 36)).toList(),
        labelStyle: const TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCenter() {
    return Expanded(
      child: ListView.separated(
        controller: _scrollController,
        itemCount: _filteredData.length,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        shrinkWrap: true,
        cacheExtent: 1000,
        itemBuilder: (context, index) {
          final d = _filteredData[index];
          return LogItemWidget(key: ValueKey(d.origin.time), verboseLogs: widget.verboseLogs, log: d);
        },
        separatorBuilder: (_, __) => _divider,
      ),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          if (_filter) ...[
            TextField(
              controller: _filterController,
              style: const TextStyle(fontSize: _fontSize),
              decoration: InputDecoration(
                hintText: t('log_viewer.filter_keywords'),
                hintStyle: const TextStyle(fontSize: _fontSize, color: Colors.black54),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: InputBorder.none,
              ),
            ),
            _divider,
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              const selects = [false, false, false, false, false];

              final buttonWidth = constraints.maxWidth / selects.length;
              return ToggleButtons(
                isSelected: selects,
                renderBorder: false,
                constraints: BoxConstraints(minHeight: 36.0, minWidth: buttonWidth),
                textStyle: const TextStyle(fontSize: _fontSize),
                onPressed: (index) {
                  switch (index) {
                    case 0:
                      _clear();
                      break;
                    case 1:
                      _scrollToTop();
                      break;
                    case 2:
                      _scrollToBottom(true);
                      break;
                    case 3:
                      _toggleLock();
                      break;
                    case 4:
                      _toggleFilter();
                      break;
                  }
                },
                children:
                    [
                      Icon(KitIcons.clear, size: 16),
                      Icon(KitIcons.top, size: 16),
                      Icon(KitIcons.down, size: 16),
                      Icon(_lock ? KitIcons.lock : KitIcons.lock_open, size: 16),
                      Icon(_filter ? KitIcons.filter_off : KitIcons.filter_on, size: 16),
                    ].map((e) => Center(child: e)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [_divider, _buildHeader(), _divider, _buildCenter(), _divider, _buildBottom()]);
  }
}
