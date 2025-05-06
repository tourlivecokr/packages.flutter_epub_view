import 'dart:collection';

import 'package:epub_view/src/ui/recommend_content_viewer_page.dart';
import 'package:flutter/material.dart';

class RecommendItem extends StatelessWidget {
  const RecommendItem({
    super.key,
    required this.baseUrl,
    this.onTourIdSelected,
    required this.attributes,
  });

  final String baseUrl;
  final Function(int tourId)? onTourIdSelected;
  final LinkedHashMap<String, String> attributes;

  @override
  Widget build(BuildContext context) {
    final trackTitle = attributes['data-tracktitle'] ?? '';
    final trackContent = attributes['data-content'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(attributes['data-creatorimage'] ?? '', width: 32, height: 32, errorBuilder: (context,_,__) {
            return Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle
              ),
            );
          }),
          const SizedBox(width: 5,),
          Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 8,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CustomPaint(
                          painter: TrianglePainter(),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: const BoxDecoration(
                              color: Color(0xffF9F9F9),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              )
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('가이드 꿀팁!',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xffFF730D),
                                    height: 20.0 / 15.0
                                ),
                              ),
                              Text(trackTitle,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff1A1A1A),
                                    height: 20.0 / 15.0
                                ),
                              ),
                              const SizedBox(height: 4,),
                              Text(trackContent,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff1A1A1A),
                                    height: 18.0 / 14.0
                                ),
                              ),
                              const SizedBox(height: 15,),
                              InkWell(
                                onTap: () {
                                  final trackImage = attributes['data-trackimage'] ?? '';
                                  final type = attributes['data-type'] ?? 'audio';

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RecommendContentViewerPage(
                                        baseUrl: baseUrl,
                                        type: type,
                                        tourId: attributes['data-tourid'] ?? '',
                                        tourTitle: trackTitle,
                                        imageUrl: trackImage,
                                        fileUrl: attributes['data-trackfile'] ?? '',
                                        onTourIdSelected: (tourId) {
                                          onTourIdSelected?.call(tourId);
                                        },
                                      )
                                    )
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                            color: Colors.black.withOpacity(0.05)
                                        )
                                      ]
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xffFF730D)
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.play_arrow, color: Colors.white, size: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 10,),
                                      const Text('가이드 설명 듣기',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xffFF730D),
                                            height: 18.0 / 14.0
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              )
          )
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffF9F9F9)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)                 // 좌상
      ..lineTo(size.width, 0)        // 우상
      ..lineTo(size.width, size.height) // 우하
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
