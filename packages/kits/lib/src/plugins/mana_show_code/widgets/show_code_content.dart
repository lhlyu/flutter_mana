import 'package:flutter/material.dart';

import '../code/code_widget.dart';
import '../code/highlighter_style.dart';
import '../utils/page_info_helper.dart';

/// 直接缓存高亮后的代码
final Map<String, _CodeInfo> _codeInfos = {};

class ShowCodeContent extends StatefulWidget {
  const ShowCodeContent({super.key});

  @override
  State<ShowCodeContent> createState() => _ShowCodeContentState();
}

class _ShowCodeContentState extends State<ShowCodeContent> {
  // 统一的字体大小
  static const double _fontSize = 12.0;

  // 分割线颜色
  static final Color _dividerColor = Colors.grey.shade200;

  late Future<_CodeInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_CodeInfo> _loadData() async {
    final helper = PageInfoHelper();
    final packagePath = helper.packagePathConvertFromFilePath(helper.filePath);

    if (_codeInfos.containsKey(packagePath)) {
      return _codeInfos[packagePath]!;
    }

    final code = await helper.getCode(packagePath) ?? '';

    final codeInfo = _CodeInfo(packagePath, code);

    _codeInfos[packagePath] = codeInfo;

    return codeInfo;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final packagePath = snapshot.data!.packagePath;
        final code = snapshot.data!.code;

        return SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, color: _dividerColor),
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  packagePath,
                  style: TextStyle(
                    fontSize: _fontSize,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1, color: _dividerColor),

              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: CodeWidget(
                    code: code,
                    style: HighlighterStyle.fromColors(HighlighterStyle.gitHub),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CodeInfo {
  final String packagePath;
  final String code;

  const _CodeInfo(this.packagePath, this.code);
}
