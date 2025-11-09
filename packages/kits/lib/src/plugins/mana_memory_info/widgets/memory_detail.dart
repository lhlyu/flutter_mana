import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

import '../utils/memory_service.dart';

/// 显示特定类的详细信息，包括属性和函数。
class MemoryDetail extends StatelessWidget with I18nMixin {
  final FormattedClassHeapStats detail;

  /// 内存服务实例。
  final MemoryService service;

  /// 构造函数。
  const MemoryDetail({super.key, required this.detail, required this.service});

  /// 从 MemoryService 获取类的详细信息。
  Future<ClsModel?> _fetchClassDetails() async {
    final completer = Completer<ClsModel?>();
    service.getClassDetailInfo(
      detail.classRef?.id ?? '',
      (info) => completer.complete(info),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          elevation: 0.0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.white,
          title: Text(detail.classRef?.name ?? ''),
        ),
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        child: FutureBuilder<ClsModel?>(
          future: _fetchClassDetails(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  t('memory_info.class_no_detail'),
                  style: TextStyle(fontSize: 20),
                ),
              );
            }

            final info = snapshot.data!;
            final propertiesText = info.properties
                .map((e) => e.propertyStr)
                .join('\n');
            final functionsText = info.functions.join('\n');

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        t('memory_info.class_name'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      detail.classRef?.name ?? '',
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        t('memory_info.location'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      detail.classRef?.location?.script?.uri ?? '',
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        t('memory_info.property'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      propertiesText,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        t('memory_info.function'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      functionsText,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
