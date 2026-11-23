import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../data/bounded_collector.dart';
import 'kit_ui.dart';

class KitFeed<T> extends StatefulWidget {
  const KitFeed({
    super.key,
    required this.collector,
    required this.categories,
    required this.categoryOf,
    required this.searchText,
    required this.itemBuilder,
  });
  final BoundedCollector<T> collector;
  final List<String> categories;
  final String Function(T) categoryOf;
  final String Function(T) searchText;
  final Widget Function(BuildContext, T) itemBuilder;
  @override
  State<KitFeed<T>> createState() => _KitFeedState<T>();
}

class _KitFeedState<T> extends State<KitFeed<T>> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  String? _category;
  bool _filter = false;
  bool _locked = false;
  bool _updateScheduled = false;
  bool _active = true;
  final _matches = HashMap<T, bool>.identity();
  List<T>? _filteredSource;
  List<T>? _filteredItems;
  String _filteredQuery = '';
  String? _filteredCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = TickerMode.valuesOf(context).enabled;
  }

  @override
  void initState() {
    super.initState();
    widget.collector.addListener(_changed);
  }

  @override
  void didUpdateWidget(KitFeed<T> old) {
    super.didUpdateWidget(old);
    if (old.collector != widget.collector) {
      old.collector.removeListener(_changed);
      widget.collector.addListener(_changed);
    }
    if (old.collector != widget.collector ||
        old.categoryOf != widget.categoryOf ||
        old.searchText != widget.searchText) {
      _invalidateFilter();
    }
  }

  void _invalidateFilter() {
    _matches.clear();
    _filteredSource = null;
    _filteredItems = null;
  }

  List<T> _filterItems(String query) {
    if (_filteredQuery != query || _filteredCategory != _category) {
      _invalidateFilter();
      _filteredQuery = query;
      _filteredCategory = _category;
    }
    final data = widget.collector.data;
    if (_category == null && query.isEmpty) return data;
    if (identical(data, _filteredSource)) return _filteredItems!;

    // Captured records are snapshots. Reuse matches while the filter is stable,
    // retaining only entries still owned by the collector.
    final retained = HashSet<T>.identity()..addAll(data);
    _matches.removeWhere((item, _) => !retained.contains(item));
    final items = data
        .where(
          (item) => _matches.putIfAbsent(
            item,
            () =>
                (_category == null || widget.categoryOf(item) == _category) &&
                (query.isEmpty ||
                    widget.searchText(item).toLowerCase().contains(query)),
          ),
        )
        .toList(growable: false);
    _filteredSource = data;
    return _filteredItems = items;
  }

  void _changed() {
    if (!mounted || !_active || _updateScheduled) return;
    _updateScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted || !_active) return;
      setState(() {});
      binding.addPostFrameCallback((_) {
        if (mounted &&
            _active &&
            !_locked &&
            _scroll.hasClients &&
            !_scroll.position.isScrollingNotifier.value) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    });
    binding.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.collector.removeListener(_changed);
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter ? _query.text.trim().toLowerCase() : '';
    final items = _filterItems(query);
    return KitScaffold(
      header: Column(
        mainAxisSize: .min,
        children: [
          KitTabs<String?>(
            values: [null, ...widget.categories],
            value: _category,
            label: (value) => value ?? kitText(context, 'common.all'),
            onChanged: (value) => setState(() => _category = value),
          ),
          if (_filter)
            KitField(
              controller: _query,
              hintText: kitText(context, 'common.search'),
              onChanged: (_) => setState(() {}),
            ),
          const KitDivider(),
        ],
      ),
      body: items.isEmpty
          ? KitMessage(kitText(context, 'common.empty'))
          : ListView.separated(
              controller: _scroll,
              primary: false,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              padding: const .only(bottom: 8),
              itemBuilder: (context, index) =>
                  widget.itemBuilder(context, items[index]),
              separatorBuilder: (_, _) => const KitDivider(),
            ),
      footer: KitToolbar(
        children: [
          KitButton(
            label: kitText(context, 'common.clear'),
            icon: .clear,
            iconOnly: true,
            onPressed: widget.collector.clear,
          ),
          KitButton(
            label: kitText(context, 'common.top'),
            icon: .top,
            iconOnly: true,
            onPressed: () {
              if (_scroll.hasClients) _scroll.jumpTo(0);
            },
          ),
          KitButton(
            label: kitText(context, 'common.bottom'),
            icon: .bottom,
            iconOnly: true,
            onPressed: () {
              if (_scroll.hasClients) {
                _scroll.jumpTo(_scroll.position.maxScrollExtent);
              }
            },
          ),
          KitButton(
            label: kitText(context, _locked ? 'common.unlock' : 'common.lock'),
            icon: _locked ? .lock : .unlock,
            iconOnly: true,
            selected: _locked,
            onPressed: () => setState(() => _locked = !_locked),
          ),
          KitButton(
            label: kitText(context, 'common.search'),
            icon: .filter,
            iconOnly: true,
            selected: _filter,
            onPressed: () => setState(() => _filter = !_filter),
          ),
        ],
      ),
    );
  }
}
