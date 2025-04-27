import 'package:epub_view/src/data/epub_cfi_reader.dart';
import 'package:epub_view/src/data/models/recommend.dart';
import 'package:html/dom.dart' as dom;

import 'models/paragraph.dart';

export 'package:epubx/epubx.dart' hide Image;

List<EpubChapter> parseChapters(EpubBook epubBook) =>
    epubBook.Chapters!.fold<List<EpubChapter>>(
      [],
      (acc, next) {
        acc.add(next);
        next.SubChapters!.forEach(acc.add);
        return acc;
      },
    );

List<dom.Element> convertDocumentToElements(dom.Document document) =>
    document.getElementsByTagName('body').first.children;

List<dom.Element> _removeAllDiv(List<dom.Element> elements) {
  final List<dom.Element> result = [];

  for (final node in elements) {
    if (node.localName == 'div' && node.children.length > 1) {
      result.addAll(_removeAllDiv(node.children));
    } else {
      result.add(node);
    }
  }

  return result;
}

ParseParagraphsResult parseParagraphs(
    List<EpubChapter> chapters,
    EpubContent? content,
    ) {
  String? filename = '';
  final List<int> chapterIndexes = [];
  final List<Paragraph> paragraphs = [];
  final List<Recommend> recommends = [];

  List<dom.Element> elmList = [];
  int lastChapterIndex = 0;
  int thisChapterLength = 0;
  for (var next in chapters) {

    // 1️⃣ 같은 파일인지 확인하고, 새로 로드
    if (filename != next.ContentFileName) {
      filename = next.ContentFileName;
      final document = EpubCfiReader().chapterDocument(next);
      if (document != null) {
        final result = convertDocumentToElements(document);
        elmList = _removeAllDiv(result);

        paragraphs.addAll(
          elmList.map((element) {
            if (element.localName == 'recommend') {
              recommends.add(Recommend(element, paragraphs.length));
            }
            return Paragraph(element, chapterIndexes.length);
          }),
        );
        lastChapterIndex += thisChapterLength;
        thisChapterLength = elmList.length;
      }
    }

    // 2️⃣ 단일 파일에서 챕터 ID 찾기 (헤딩 태그 기반)
    int chapterStartIndex = lastChapterIndex; // 현재까지의 Paragraph 개수 저장
    if (next.Anchor != null) {
      final index = elmList.indexWhere(
            (elm) => elm.outerHtml.contains('id="${next.Anchor}"'),
      );

      // 앵커가 문서에서 존재하지 않는다면, 그냥 현재 인덱스 사용
      chapterStartIndex = (index != -1) ? chapterStartIndex + index : chapterStartIndex;
    }

    // 3️⃣ `chapterIndexes`에 챕터 시작 위치 추가
    chapterIndexes.add(chapterStartIndex);
  }

  return ParseParagraphsResult(paragraphs, chapterIndexes, recommends);
}

class ParseParagraphsResult {
  ParseParagraphsResult(this.flatParagraphs, this.chapterIndexes, this.recommends);

  final List<Paragraph> flatParagraphs;
  final List<int> chapterIndexes;
  final List<Recommend> recommends;
}
