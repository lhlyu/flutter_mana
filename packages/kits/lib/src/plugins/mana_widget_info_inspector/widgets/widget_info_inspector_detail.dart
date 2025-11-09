import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/icons/kit_icons.dart';

/// 用于封装每个 Element 及其随机颜色信息
class _ElementDetail {
  final Element element;
  final Color color;

  _ElementDetail(this.element)
    : color = Color.fromARGB(
        255,
        Random().nextInt(256),
        Random().nextInt(256),
        Random().nextInt(256),
      );
}

/// widget 构建链页面，用于展示所有 widget 元素及其跳转详情能力
class InfoPage extends StatefulWidget {
  const InfoPage({super.key, required this.elements});

  /// 传入的 widget 元素链
  final List<Element> elements;

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_ElementDetail> _originalList = [];
  List<_ElementDetail> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _originalList.addAll(widget.elements.map((e) => _ElementDetail(e)));
    _filteredList = List.from(_originalList);
  }

  /// 构建左侧彩色圆点
  Widget _buildColorDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// 构建单行展示 item
  Widget _buildItem(_ElementDetail model) {
    return GestureDetector(
      onTap: () => _navigateToDetail(model.element),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildColorDot(model.color),
            ),
            Expanded(
              child: Text(
                model.element.widget.toStringShort(),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 页面跳转至详情页
  void _navigateToDetail(Element element) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                elevation: 0.0,
                backgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                title: const Text("Widget Detail"),
              ),
              body: _ElementDetailPage(element: element),
            ),
      ),
    );
  }

  /// 搜索处理逻辑
  void _onSearchChanged([String query = '']) {
    query = query.trim();
    if (query.isEmpty) {
      setState(() => _filteredList = List.from(_originalList));
      return;
    }
    final RegExp reg = RegExp(query, caseSensitive: false);
    setState(() {
      _filteredList =
          _originalList
              .where(
                (item) => reg.hasMatch(item.element.widget.toStringShort()),
              )
              .toList();
    });
  }

  void _clear() {
    _searchController.text = '';
    _onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: RichText(
            text: TextSpan(
              text: 'widget_build_chain',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: '  depth: ${widget.elements.length}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 搜索框区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search widget',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(KitIcons.search),
                suffixIcon: InkWell(
                  onTap: _clear,
                  child: const Icon(KitIcons.close),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child:
                  _filteredList.isEmpty
                      ? const Center(child: Text('No match found'))
                      : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredList.length,
                        itemBuilder:
                            (_, index) => _buildItem(_filteredList[index]),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// widget 元素详情展示页
class _ElementDetailPage extends StatelessWidget {
  const _ElementDetailPage({required this.element});

  final Element element;

  /// 标题组件
  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 获取 RenderObject 的详细信息
  Future<List<String>> _getRenderObjectInfo() async {
    final renderStr = element.renderObject?.toStringDeep() ?? '';
    return renderStr.split('\n');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getRenderObjectInfo(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          );
        } else if (snapshot.hasData) {
          final text = snapshot.data!.join('\n');

          return SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle("Widget Description"),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Text(element.widget.toStringDeep()),
                  ),
                ),
                _buildTitle("RenderObject Description"),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Text(text),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text('Load failed'));
        }
      },
    );
  }
}
