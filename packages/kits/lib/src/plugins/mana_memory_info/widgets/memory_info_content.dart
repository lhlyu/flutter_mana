import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:vm_service/vm_service.dart';

import '../../../ui/kit_ui.dart';
import '../utils/memory_service.dart';
import 'memory_detail.dart';

class MemoryInfoContent extends StatefulWidget {
  const MemoryInfoContent({super.key, this.service});
  final MemoryService? service;
  @override
  State<MemoryInfoContent> createState() => _MemoryInfoContentState();
}

class _MemoryInfoContentState extends State<MemoryInfoContent> {
  late MemoryService _service = widget.service ?? MemoryService();
  final _query = TextEditingController();
  bool _private = false;
  String _sort = 'Size';
  bool _ascending = false;
  int _revision = 0;
  ClassHeapStats? _selected;
  @override
  void didUpdateWidget(MemoryInfoContent old) {
    super.didUpdateWidget(old);
    if (old.service == widget.service) return;
    if (old.service == null) unawaited(_service.close());
    _service = widget.service ?? MemoryService();
    _selected = null;
    _revision++;
  }

  @override
  void dispose() {
    _query.dispose();
    if (widget.service == null) unawaited(_service.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selected case final item?) {
      return MemoryDetail(
        detail: item,
        service: _service,
        onClose: () => setState(() => _selected = null),
      );
    }
    return KitAsync<MemorySnapshot>(
      key: ValueKey(_revision),
      load: _service.load,
      builder: (context, snapshot) {
        final query = _query.text.toLowerCase();
        final items = snapshot.classes
            .where(
              (item) =>
                  (_private ||
                      !(item.classRef?.name?.startsWith('_') ?? false)) &&
                  '${item.classRef?.name} ${item.classRef?.location?.script?.uri}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
        items.sort((a, b) {
          final result = switch (_sort) {
            'Size' => (a.bytesCurrent ?? 0).compareTo(b.bytesCurrent ?? 0),
            'Count' => (a.instancesCurrent ?? 0).compareTo(
              b.instancesCurrent ?? 0,
            ),
            _ => (a.classRef?.name ?? '').compareTo(b.classRef?.name ?? ''),
          };
          return _ascending ? result : -result;
        });
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  KitDataTable({
                    'PID': snapshot.vm.pid,
                    'CPU': snapshot.vm.hostCPU,
                    'VM': snapshot.vm.version,
                    'Heap': MemoryService.formatBytes(
                      snapshot.usage.heapUsage ?? 0,
                    ),
                    'Capacity': MemoryService.formatBytes(
                      snapshot.usage.heapCapacity ?? 0,
                    ),
                    'External': MemoryService.formatBytes(
                      snapshot.usage.externalUsage ?? 0,
                    ),
                    'Classes': items.length,
                  }),
                  KitField(
                    controller: _query,
                    label: kitText(context, 'common.search'),
                    onChanged: (_) => setState(() {}),
                  ),
                  KitToggle(
                    label: kitText(context, 'memory_info.hide_private_classes'),
                    value: !_private,
                    onChanged: (value) => setState(() => _private = !value),
                  ),
                  KitToolbar(
                    children: [
                      for (final (field, key) in [
                        ('Size', 'memory_info.size'),
                        ('Count', 'memory_info.number'),
                        ('Class', 'memory_info.class_name'),
                      ])
                        KitButton(
                          label: kitText(context, key),
                          selected: _sort == field,
                          icon: _sort != field
                              ? .sort
                              : _ascending
                              ? .sortAsc
                              : .sortDesc,
                          onPressed: () => setState(() {
                            if (_sort == field) {
                              _ascending = !_ascending;
                            } else {
                              _sort = field;
                              _ascending = field == 'Class';
                            }
                          }),
                        ),
                      KitButton(
                        label: kitText(context, 'common.refresh'),
                        icon: .refresh,
                        iconOnly: true,
                        onPressed: () => setState(() => _revision++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ManaButton(
                  onPressed: () => setState(() => _selected = item),
                  padding: const .all(10),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          item.classRef?.name ?? '—',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${item.instancesCurrent ?? 0}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: KitStyle.muted,
                        ),
                      ),
                      Text(
                        MemoryService.formatBytes(item.bytesCurrent ?? 0),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
