import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:epub_view/src/data/epub_cfi_reader.dart';
import 'package:epub_view/src/data/epub_parser.dart';
import 'package:epub_view/src/data/models/chapter.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';
import 'package:epub_view/src/data/models/paragraph.dart';
import 'package:epub_view/src/data/models/recommend.dart';
import 'package:epub_view/src/ui/recommend_content_viewer_page.dart';
import 'package:epub_view/src/ui/recommend_item.dart';
import 'package:epub_view/src/ui/table_of_recommends.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:html/parser.dart' as html_parser;

export 'package:epubx/epubx.dart' hide Image;

part '../epub_controller.dart';
part '../helpers/epub_view_builders.dart';

const _minTrailingEdge = 0.55;
const _minLeadingEdge = -0.05;

typedef ExternalLinkPressed = void Function(String href);

class EpubView extends StatefulWidget {
  const EpubView({
    required this.controller,
    this.onExternalLinkPressed,
    this.onChapterChanged,
    this.onDocumentLoaded,
    this.onDocumentError,
    this.onLastItem,
    this.builders = const EpubViewBuilders<DefaultBuilderOptions>(
      options: DefaultBuilderOptions(),
    ),
    this.shrinkWrap = false,
    this.tourId = 0,
    this.baseUrl = 'https://api.tourlive.co.kr',
    this.onTourIdSelected,
    Key? key,
  }) : super(key: key);

  final EpubController controller;
  final ExternalLinkPressed? onExternalLinkPressed;
  final bool shrinkWrap;
  final void Function(EpubChapterViewValue? value)? onChapterChanged;

  /// Called when a document is loaded
  final void Function(EpubBook document)? onDocumentLoaded;

  /// Called when a document loading error
  final void Function(Exception? error)? onDocumentError;

  final void Function()? onLastItem;

  /// Builders
  final EpubViewBuilders builders;

  final int tourId;
  final String baseUrl;
  final Function(int tourId)? onTourIdSelected;

  @override
  State<EpubView> createState() => _EpubViewState();
}

class _EpubViewState extends State<EpubView> {
  Exception? _loadingError;
  ItemScrollController? _itemScrollController;
  ItemPositionsListener? _itemPositionListener;
  List<EpubChapter> _chapters = [];
  List<Paragraph> _paragraphs = [];
  EpubCfiReader? _epubCfiReader;
  EpubChapterViewValue? _currentValue;
  final _chapterIndexes = <int>[];
  final _recommends = <Recommend>[];

  EpubController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionListener = ItemPositionsListener.create();
    _controller._attach(this);
    _controller.loadingState.addListener(() {
      switch (_controller.loadingState.value) {
        case EpubViewLoadingState.loading:
          break;
        case EpubViewLoadingState.success:
          widget.onDocumentLoaded?.call(_controller._document!);
          break;
        case EpubViewLoadingState.error:
          widget.onDocumentError?.call(_loadingError);
          break;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _itemPositionListener!.itemPositions.removeListener(_changeListener);
    _controller._detach();
    super.dispose();
  }

  Future<bool> _init() async {
    if (_controller.isBookLoaded.value) {
      return true;
    }
    _chapters = parseChapters(_controller._document!);
    final parseParagraphsResult =
        parseParagraphs(_chapters, _controller._document!.Content);
    _paragraphs = parseParagraphsResult.flatParagraphs;
    _chapterIndexes.addAll(parseParagraphsResult.chapterIndexes);
    _recommends.addAll(parseParagraphsResult.recommends);

    _epubCfiReader = EpubCfiReader.parser(
      cfiInput: _controller.epubCfi,
      chapters: _chapters,
      paragraphs: _paragraphs,
    );
    _itemPositionListener!.itemPositions.addListener(_changeListener);
    _controller.isBookLoaded.value = true;

    return true;
  }

  void _changeListener() {
    if (_paragraphs.isEmpty ||
        _itemPositionListener!.itemPositions.value.isEmpty) {
      return;
    }
    final position = _itemPositionListener!.itemPositions.value.first;
    final chapterIndex = _getChapterIndexBy(
      positionIndex: position.index,
      trailingEdge: position.itemTrailingEdge,
      leadingEdge: position.itemLeadingEdge,
    );
    final paragraphIndex = _getParagraphIndexBy(
      positionIndex: position.index,
      trailingEdge: position.itemTrailingEdge,
      leadingEdge: position.itemLeadingEdge,
    );
    _currentValue = EpubChapterViewValue(
      chapter: chapterIndex >= 0 ? _chapters[chapterIndex] : null,
      chapterNumber: chapterIndex + 1,
      paragraphNumber: paragraphIndex + 1,
      position: position,
    );
    _controller.currentValueListenable.value = _currentValue;
    widget.onChapterChanged?.call(_currentValue);

    // 끝까지 읽었는지 체크
    final positions = _itemPositionListener!.itemPositions.value;

    if (positions.isNotEmpty) {
      final lastItem = positions.last;
      if (lastItem.itemTrailingEdge <= 1.0) {
        // 마지막 아이템이 완전히 화면에 보일 때
        widget.onLastItem?.call();
      }
    }
  }

  void _gotoEpubCfi(
    String? epubCfi, {
    double alignment = 0,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
  }) {
    _epubCfiReader?.epubCfi = epubCfi;
    final index = _epubCfiReader?.paragraphIndexByCfiFragment;

    if (index == null) {
      return;
    }

    _itemScrollController?.scrollTo(
      index: index,
      duration: duration,
      alignment: alignment,
      curve: curve,
    );
  }

  void _onLinkPressed(String href) {
    if (href.contains('://')) {
      widget.onExternalLinkPressed?.call(href);
      return;
    }

    // Chapter01.xhtml#ph1_1 -> [ph1_1, Chapter01.xhtml] || [ph1_1]
    String? hrefIdRef;
    String? hrefFileName;

    if (href.contains('#')) {
      final dividedHref = href.split('#');
      if (dividedHref.length == 1) {
        hrefIdRef = href;
      } else {
        hrefFileName = dividedHref[0];
        hrefIdRef = dividedHref[1];
      }
    } else {
      hrefFileName = href;
    }

    if (hrefIdRef == null) {
      final chapter = _chapterByFileName(hrefFileName);
      if (chapter != null) {
        final cfi = _epubCfiReader?.generateCfiChapter(
          book: _controller._document,
          chapter: chapter,
          additional: ['/4/2'],
        );

        _gotoEpubCfi(cfi);
      }
      return;
    } else {
      final paragraph = _paragraphByIdRef(hrefIdRef);
      final chapter =
          paragraph != null ? _chapters[paragraph.chapterIndex] : null;

      if (chapter != null && paragraph != null) {
        final paragraphIndex =
            _epubCfiReader?.getParagraphIndexByElement(paragraph.element);
        final cfi = _epubCfiReader?.generateCfi(
          book: _controller._document,
          chapter: chapter,
          paragraphIndex: paragraphIndex,
        );

        _gotoEpubCfi(cfi);
      }

      return;
    }
  }

  Paragraph? _paragraphByIdRef(String idRef) =>
      _paragraphs.firstWhereOrNull((paragraph) {
        if (paragraph.element.id == idRef) {
          return true;
        }

        return paragraph.element.children.isNotEmpty &&
            paragraph.element.children[0].id == idRef;
      });

  EpubChapter? _chapterByFileName(String? fileName) =>
      _chapters.firstWhereOrNull((chapter) {
        if (fileName != null) {
          if (chapter.ContentFileName!.contains(fileName)) {
            return true;
          } else {
            return false;
          }
        }
        return false;
      });

  int _getChapterIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    final posIndex = _getAbsParagraphIndexBy(
      positionIndex: positionIndex,
      trailingEdge: trailingEdge,
      leadingEdge: leadingEdge,
    );
    final index = posIndex >= _chapterIndexes.last
        ? _chapterIndexes.length
        : _chapterIndexes.indexWhere((chapterIndex) {
            if (posIndex < chapterIndex) {
              return true;
            }
            return false;
          });

    return index - 1;
  }

  int _getParagraphIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    final posIndex = _getAbsParagraphIndexBy(
      positionIndex: positionIndex,
      trailingEdge: trailingEdge,
      leadingEdge: leadingEdge,
    );

    final index = _getChapterIndexBy(positionIndex: posIndex);

    if (index == -1) {
      return posIndex;
    }

    return posIndex - _chapterIndexes[index];
  }

  int _getAbsParagraphIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    int posIndex = positionIndex;
    if (trailingEdge != null &&
        leadingEdge != null &&
        trailingEdge < _minTrailingEdge &&
        leadingEdge < _minLeadingEdge) {
      posIndex += 1;
    }

    return posIndex;
  }

  static Widget _chapterDividerBuilder(EpubChapter chapter) => Container();

  static Widget _chapterBuilder(
    BuildContext context,
    EpubViewBuilders builders,
    EpubBook document,
    List<EpubChapter> chapters,
    List<Paragraph> paragraphs,
    int index,
    int chapterIndex,
    int paragraphIndex,
    ExternalLinkPressed onExternalLinkPressed,
    int tourId,
    String baseUrl,
    Function(int tourId)? onTourIdSelected,
  ) {
    if (paragraphs.isEmpty) {
      return Container();
    }

    final defaultBuilder = builders as EpubViewBuilders<DefaultBuilderOptions>;
    final options = defaultBuilder.options;

    return Container(
      decoration: BoxDecoration(color: options.backgroundColor),
      child: Column(
        children: <Widget>[
          if (chapterIndex >= 0 && paragraphIndex == 0)
            builders.chapterDividerBuilder(chapters[chapterIndex]),
          Html(
            data: paragraphs[index].element.outerHtml,
            onLinkTap: (href, _, __) => onExternalLinkPressed(href!),
            style: {
              'html': Style(
                padding: HtmlPaddings.only(
                  top: (options.paragraphPadding as EdgeInsets?)?.top,
                  right: (options.paragraphPadding as EdgeInsets?)?.right,
                  bottom: (options.paragraphPadding as EdgeInsets?)?.bottom,
                  left: (options.paragraphPadding as EdgeInsets?)?.left,
                ),
              ).merge(Style.fromTextStyle(options.textStyle)),
            },
            extensions: [
              /*TagExtension(
                tagsToExtend: {"img"},
                builder: (imageContext) {
                  final url =
                      imageContext.attributes['src']!.replaceAll('../', '');
                  final content = Uint8List.fromList(
                      document.Content!.Images![url]!.Content!);
                  return Image(
                    image: MemoryImage(content),
                  );
                },
              ),*/
              TagExtension(
                tagsToExtend: {"img"},
                builder: (imageContext) {
                  final url = imageContext.attributes['src']!.replaceAll('../', '');
                  return InkWell(
                    onTap: () {
                      showImageViewer(context, Image.file(File(document.Content!.Images![url]!.imagePath!)).image);
                    },
                    child: Image.file(File(document.Content!.Images![url]!.imagePath!))
                  );
                },
              ),
              TagExtension(
                tagsToExtend: {"player"},
                builder: (spanContext) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: RecommendItem(attributes: spanContext.attributes, tourId: tourId, baseUrl: baseUrl,
                      onTourIdSelected: (tourId) {
                        onTourIdSelected?.call(tourId);
                      }
                    ),
                  );
                }
              ),
              TagExtension(
                tagsToExtend: {"intro"},
                builder: (spanContext) {
                  final dataTitle = spanContext.elementChildren.firstWhereOrNull((element) => element.localName == 'data-title')?.text ?? '';
                  final dataBody = spanContext.elementChildren.firstWhereOrNull((element) => element.localName == 'data-body')?.text ?? '';
                  final player = spanContext.elementChildren.firstWhereOrNull((element) => element.localName == 'player');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dataTitle,
                        style: options.textStyle,
                        /*style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1A1A1A),
                          height: 1.3
                        ),*/
                      ),
                      const SizedBox(height: 15,),
                      Text(dataBody,
                        style: options.textStyle,
                        /*style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff3A3A3A),
                          height: 22.0 / 16.0
                        ),*/
                      ),
                      const SizedBox(height: 46,),
                      Text('샘플',
                        style: options.textStyle,
                        /*style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff3A3A3A),
                          height: 26.0 / 18.0
                        ),*/
                      ),
                      const SizedBox(height: 20,),
                      if (player != null)
                        RecommendItem(attributes: Map<String, String>.from(player.attributes), tourId: tourId, baseUrl: baseUrl,
                          onTourIdSelected: (tourId) {
                            onTourIdSelected?.call(tourId);
                          }
                        ),
                      const SizedBox(height: 12,),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE1E1E1),
                      ),
                      const SizedBox(height: 30,)
                    ],
                  );
                }
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ScrollablePositionedList.builder(
            shrinkWrap: widget.shrinkWrap,
            initialScrollIndex: _epubCfiReader!.paragraphIndexByCfiFragment ?? 0,
            itemCount: _controller.isEpubDemo ? (_chapterIndexes.length > 3 ? _chapterIndexes[3] : _chapterIndexes.length) : _paragraphs.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionListener,
            itemBuilder: (BuildContext context, int index) {
              return widget.builders.chapterBuilder(
                context,
                widget.builders,
                widget.controller._document!,
                _chapters,
                _paragraphs,
                index,
                _getChapterIndexBy(positionIndex: index),
                _getParagraphIndexBy(positionIndex: index),
                _onLinkPressed,
                widget.tourId,
                widget.baseUrl,
                widget.onTourIdSelected,
              );
            },
          ),
        ),
        if (_recommends.isNotEmpty)
          Positioned(
            right: 20,
            bottom: 25,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EpubViewTableOfRecommends(controller: _controller,
                      tourId: widget.tourId,
                      baseUrl: widget.baseUrl,
                      onTourIdSelected: (tourId) {
                        widget.onTourIdSelected?.call(tourId);
                      }
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF730D),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_play, color: Colors.white, size: 24,),
                    //Image.asset('assets/images/list_play.png', width: 16, height: 16),
                    SizedBox(width: 4,),
                    Text('가이드꿀팁',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 18.0 / 14.0
                      ),
                    )
                  ],
                ),
              ),
            )
          )
      ],
    );
  }

  static Widget _builder(
    BuildContext context,
    EpubViewBuilders builders,
    EpubViewLoadingState state,
    WidgetBuilder loadedBuilder,
    Exception? loadingError,
  ) {
    final Widget content = () {
      switch (state) {
        case EpubViewLoadingState.loading:
          return KeyedSubtree(
            key: const Key('epubx.root.loading'),
            child: builders.loaderBuilder?.call(context) ?? const SizedBox(),
          );
        case EpubViewLoadingState.error:
          return KeyedSubtree(
            key: const Key('epubx.root.error'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: builders.errorBuilder?.call(context, loadingError!) ??
                  Center(child: Text(loadingError.toString())),
            ),
          );
        case EpubViewLoadingState.success:
          return KeyedSubtree(
            key: const Key('epubx.root.success'),
            child: loadedBuilder(context),
          );
      }
    }();

    final defaultBuilder = builders as EpubViewBuilders<DefaultBuilderOptions>;
    final options = defaultBuilder.options;

    return AnimatedSwitcher(
      duration: options.loaderSwitchDuration,
      transitionBuilder: options.transitionBuilder,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builders.builder(
      context,
      widget.builders,
      _controller.loadingState.value,
      _buildLoaded,
      _loadingError,
    );
  }
}
