import 'dart:collection';

import 'package:epub_view/src/data/models/chapter.dart';
import 'package:epub_view/src/data/models/recommend.dart';
import 'package:epub_view/src/ui/epub_view.dart';
import 'package:epub_view/src/ui/recommend_item.dart';
import 'package:epub_view/src/util/mixpanel_manager.dart';
import 'package:flutter/material.dart';

class EpubViewTableOfRecommends extends StatefulWidget {
  const EpubViewTableOfRecommends({
    required this.controller,
    this.padding,
    this.itemBuilder,
    this.loader,
    this.tourId = 0,
    this.baseUrl = '',
    this.onTourIdSelected,
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
  final int tourId;
  final String baseUrl;
  final Function(int index)? onTourIdSelected;

  @override
  State<EpubViewTableOfRecommends> createState() => _EpubViewTableOfContentsState();
}

class _EpubViewTableOfContentsState extends State<EpubViewTableOfRecommends> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가이드꿀팁 듣기', style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 26.0 / 18.0
        )),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xFF000000), size: 24,),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ValueListenableBuilder<List<Recommend>>(
        valueListenable: widget.controller.recommendsListenable,
        builder: (_, recommends, __) {
          return recommends.isEmpty
              ? const Center(
                  child: Text('가이드 꿀팁이 없습니다.'),
                )
              : ListView.builder(
            controller: _scrollController,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: InkWell(
                  onTap: () {
                    MixpanelManager.init();
                    MixpanelManager.instance?.track(
                      'EventOn_ClickPlaylistFromEbook',
                      properties: {
                        'tour_id': widget.tourId.toString(),
                        'track_title': recommends[index].element.text,
                      }
                    );
                    widget.controller.scrollTo(index: recommends[index].index);
                    Navigator.of(context).pop();
                  },
                  child: RecommendItem(
                    baseUrl: widget.baseUrl,
                    tourId: widget.tourId,
                    attributes: Map<String, String>.from(recommends[index].element.attributes),
                    onTourIdSelected: widget.onTourIdSelected,
                  )
                ),
              );
            },
            itemCount: recommends.length,
          );
        }
      ),
    );
  }
}
