import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/memory_service.dart';
import 'memory_detail.dart';

class MemoryInfoContent extends StatefulWidget {
  const MemoryInfoContent({super.key});

  @override
  State<MemoryInfoContent> createState() => _MemoryInfoContentState();
}

class _MemoryInfoContentState extends State<MemoryInfoContent> with I18nMixin {
  final MemoryService _memoryService = MemoryService();

  String _pkg = '';
  String _currentSortField = 'accumulatedSize';
  bool _isAscending = false;
  bool _hidePrivateClasses = true;
  bool _onlyCurrentPackage = false;
  bool _dataReady = false;

  List<FormattedClassHeapStats> get _filteredItems {
    var items = _memoryService.classHeapStatsList;

    if (_hidePrivateClasses) {
      items = items.where((v) => !(v.classRef?.name?.startsWith('_') ?? false)).toList();
    }

    if (_onlyCurrentPackage && _pkg.isNotEmpty) {
      items = items.where((v) => (v.classRef?.location?.script?.uri?.contains(_pkg) ?? false)).toList();
    }

    return items;
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _memoryService.getInfos(() {}),
      PackageInfo.fromPlatform().then((info) {
        _pkg = 'package:${info.packageName.split('.').last}/';
      }),
    ]);

    _sortClassHeapStats(); // 初始排序
    setState(() => _dataReady = true);
  }

  void _sortClassHeapStats() {
    switch (_currentSortField) {
      case 'accumulatedSize':
        _memoryService.sortClassHeapStats(
          (stats) => stats.accumulatedSize ?? 0,
          !_isAscending,
          () {},
        );
        break;
      case 'instancesCurrent':
        _memoryService.sortClassHeapStats(
          (stats) => stats.instancesCurrent ?? 0,
          !_isAscending,
          () {},
        );
        break;
      case 'className':
        _memoryService.sortClassHeapStats(
          (stats) => stats.classRef?.name ?? '',
          _isAscending,
          () {},
        );
        break;
    }
  }

  void _onSortChanged(String field) {
    setState(() {
      if (_currentSortField == field) {
        _isAscending = !_isAscending;
      } else {
        _currentSortField = field;
        _isAscending = false;
      }
      _sortClassHeapStats();
    });
  }

  Widget _buildTableHeaderCol({int flex = 1, required String field, required String label}) {
    final icon =
        _currentSortField == field ? (_isAscending ? KitIcons.sort_asc : KitIcons.sort_desc) : KitIcons.sort_auto;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _onSortChanged(field),
        child: Row(
          children: [
            Text(t(label), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Icon(icon, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildCheckboxRow(bool value, String label, VoidCallback onChanged) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            value: value,
            onChanged: (_) => setState(onChanged),
          ),
        ),
        const SizedBox(width: 5),
        Text(t(label)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final vmInfo = _memoryService.vmInfo;
    final memoryInfo = _memoryService.memoryUsageInfo;
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            toolbarHeight: 0,
            expandedHeight: 420.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(t('memory_info.vm_info'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildTableRow('PID:', '${vmInfo?.pid ?? 'N/A'}'),
                    _buildTableRow('CPU:', vmInfo?.hostCPU ?? 'N/A'),
                    _buildTableRow(t('memory_info.version'), vmInfo?.version ?? 'N/A'),
                    const SizedBox(height: 16),
                    Text(t('memory_info.memory_info'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildTableRow(
                        'Heap Usage:',
                        '${memoryInfo?.heapUsageFormatted ?? 'N/A'} / '
                            '${memoryInfo?.heapCapacityFormatted ?? 'N/A'}'),
                    _buildTableRow('External Usage:', memoryInfo?.externalUsageFormatted ?? 'N/A'),
                    const SizedBox(height: 16),
                    _buildCheckboxRow(_hidePrivateClasses, 'memory_info.hide_private_classes', () {
                      _hidePrivateClasses = !_hidePrivateClasses;
                    }),
                    const SizedBox(height: 4),
                    _buildCheckboxRow(_onlyCurrentPackage, 'memory_info.current_app', () {
                      _onlyCurrentPackage = !_onlyCurrentPackage;
                    }),
                    const SizedBox(height: 4),
                    _buildTableRow(t('memory_info.total'), '${items.length}'),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(39),
              child: Container(
                color: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildTableHeaderCol(field: 'accumulatedSize', label: 'memory_info.size'),
                    _buildTableHeaderCol(field: 'instancesCurrent', label: 'memory_info.number'),
                    _buildTableHeaderCol(flex: 3, field: 'className', label: 'memory_info.class_name'),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                final isEven = index.isOdd;

                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MemoryDetail(detail: item, service: _memoryService),
                    ),
                  ),
                  child: Container(
                    color: isEven ? Colors.grey.shade100 : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text(item.accumulatedSizeFormatted)),
                        Expanded(flex: 1, child: Text('${item.instancesCurrent ?? 'N/A'}')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.classRef?.name ?? 'Unknown Class',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        ],
      ),
    );
  }
}
