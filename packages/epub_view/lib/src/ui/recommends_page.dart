import 'package:epub_view/src/data/models/chapter.dart';
import 'package:epub_view/src/data/models/recommend.dart';
import 'package:epub_view/src/ui/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';

class RecommendsPage extends StatefulWidget {
  const RecommendsPage({
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
  State<RecommendsPage> createState() => _RecommendsPageState();
}

class _RecommendsPageState extends State<RecommendsPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Recommend>>(
      valueListenable: widget.controller.recommendsListenable,
      builder: (_, recommends, __) {
        if (recommends.isEmpty) {
          return widget.loader ?? const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: widget.padding,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                widget.controller.scrollTo(index: recommends[index].index);
                Navigator.of(context).pop();
              },
              child: Container(
                  height: 44, // 높이 44 고정
                  alignment: Alignment.centerLeft, // 센터 정렬
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    recommends[index].element.text.trim(),
                    maxLines: 1, // 최대 1줄
                    overflow: TextOverflow.ellipsis, // 넘치면 "..."
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  )
              ),
            );
          },
          itemCount: recommends.length,
        );
      },
    );
  }
}
