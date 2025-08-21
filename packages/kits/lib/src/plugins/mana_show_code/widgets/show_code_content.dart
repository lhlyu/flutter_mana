import 'package:flutter/material.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

import '../utils/page_info_helper.dart';

/// 直接缓存高亮后的代码
final Map<String, TextSpan> _sourceCodes = {};

class ShowCodeContent extends StatefulWidget {
  final Highlighter highlighter;

  const ShowCodeContent({super.key, required this.highlighter});

  @override
  State<ShowCodeContent> createState() => _ShowCodeContentState();
}

class _ShowCodeContentState extends State<ShowCodeContent> {
  // 统一的字体大小
  static const double _fontSize = 12.0;

  // 分割线颜色
  static final Color _dividerColor = Colors.grey.shade200;

  late Future<_ShowCodeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_ShowCodeData> _loadData() async {
    final helper = PageInfoHelper();
    final packagePath = helper.packagePathConvertFromFilePath(helper.filePath);

    if (_sourceCodes.containsKey(packagePath)) {
      return _ShowCodeData(packagePath, _sourceCodes[packagePath]!);
    }

    final code = await helper.getCode(packagePath);

    final textSpan = widget.highlighter.highlight(code ?? '');

    _sourceCodes[packagePath] = textSpan;

    return _ShowCodeData(packagePath, textSpan);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final packagePath = snapshot.data!.packagePath;
        final textSpan = snapshot.data!.textSpan;

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
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Text.rich(
                          textSpan,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _ShowCodeData {
  final String packagePath;
  final TextSpan textSpan;

  const _ShowCodeData(this.packagePath, this.textSpan);
}
