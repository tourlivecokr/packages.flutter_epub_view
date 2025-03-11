import 'package:epub_view/src/data/models/chapter.dart';
import 'package:epub_view/src/ui/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';

class EpubViewTableOfContents extends StatefulWidget {
  const EpubViewTableOfContents({
    required this.controller,
    this.padding,
    this.itemBuilder,
    this.loader,
    Key? key,
  }) : super(key: key);

  final EdgeInsetsGeometry? padding;
  final EpubController controller;
  final Widget Function(
      BuildContext context,
      int index,
      EpubViewChapter chapter,
      int itemCount,
      )? itemBuilder;
  final Widget? loader;

  @override
  State<EpubViewTableOfContents> createState() => _EpubViewTableOfContentsState();
}

class _EpubViewTableOfContentsState extends State<EpubViewTableOfContents> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 📌 현재 페이지 위치를 기반으로 스크롤 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveChapter();
    });

    // 📌 현재 페이지 위치가 변경될 때 자동 스크롤
    widget.controller.currentValueListenable.addListener(_scrollToActiveChapter);
  }

  @override
  void dispose() {
    widget.controller.currentValueListenable.removeListener(_scrollToActiveChapter);
    _scrollController.dispose();
    super.dispose();
  }

  // 🔥 현재 읽고 있는 챕터로 스크롤 이동
  void _scrollToActiveChapter() {
    final currentIndex = widget.controller.currentValueListenable?.value?.position.index;
    final tableOfContents = widget.controller.tableOfContentsListenable.value;

    if (currentIndex == null || tableOfContents.isEmpty) return;

    // 현재 읽고 있는 챕터 찾기
    int targetIndex = tableOfContents.indexWhere((chapter) =>
    currentIndex >= chapter.startIndex &&
        (tableOfContents.length - 1 == tableOfContents.indexOf(chapter) ||
            currentIndex < tableOfContents[tableOfContents.indexOf(chapter) + 1].startIndex));

    if (targetIndex != -1) {
      _scrollController.animateTo(
        targetIndex * 50.0, // 📌 ListTile 높이를 고려한 이동
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<EpubViewChapter>>(
      valueListenable: widget.controller.tableOfContentsListenable,
      builder: (_, tableOfContents, __) {
        return ValueListenableBuilder<EpubChapterViewValue?>(
          valueListenable: widget.controller.currentValueListenable,
          builder: (_, currentValue, __) {
            if (tableOfContents.isEmpty) {
              return widget.loader ?? const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              controller: _scrollController, // 📌 스크롤 컨트롤러 적용
              padding: widget.padding,
              itemBuilder: (context, index) {
                bool isActive = currentValue?.position.index != null &&
                    index < tableOfContents.length &&
                    currentValue!.position.index >= tableOfContents[index].startIndex &&
                    (index == tableOfContents.length - 1 ||
                        currentValue!.position.index < tableOfContents[index + 1].startIndex);

                return ListTile(
                  title: Text(
                    tableOfContents[index].title!.trim(),
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.blue : Colors.black,
                    ),
                  ),
                  onTap: () => widget.controller.scrollTo(index: tableOfContents[index].startIndex),
                  selected: isActive, // ✅ 활성화 상태 적용
                );
              },
              itemCount: tableOfContents.length,
            );
          },
        );
      },
    );
  }
}
