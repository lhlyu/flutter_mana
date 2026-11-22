import 'package:flutter/widgets.dart';
import 'package:vm_service/vm_service.dart';

import '../../../ui/kit_ui.dart';
import '../utils/memory_service.dart';

class MemoryDetail extends StatelessWidget {
  const MemoryDetail({
    super.key,
    required this.detail,
    required this.service,
    required this.onClose,
  });
  final ClassHeapStats detail;
  final MemoryService service;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => KitDetail(
    title: detail.classRef?.name ?? '',
    onClose: onClose,
    child: KitAsync<Class?>(
      loadKey: (service, detail.classRef?.id),
      load: () => service.classDetails(detail.classRef?.id ?? ''),
      builder: (context, info) {
        if (info == null) {
          return KitMessage(kitText(context, 'memory_info.class_no_detail'));
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              KitDataTable({
                'Class': detail.classRef?.name,
                'Location': detail.classRef?.location?.script?.uri,
              }),
              KitSection(
                kitText(context, 'memory_info.fields'),
                child: KitCode(
                  [
                    for (final field in info.fields ?? <FieldRef>[])
                      [
                        if (field.isStatic == true) 'static',
                        if (field.isConst == true)
                          'const'
                        else if (field.isFinal == true)
                          'final',
                        field.declaredType?.name ?? 'dynamic',
                        field.name ?? '—',
                      ].join(' '),
                  ].join('\n'),
                ),
              ),
              KitSection(
                kitText(context, 'memory_info.functions'),
                child: KitCode(
                  (info.functions ?? <FuncRef>[])
                      .map((function) => function.name ?? '—')
                      .join('\n'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
