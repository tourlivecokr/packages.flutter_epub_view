import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:epub_view/src/ui/recommend_content_viewer_page.dart';
import 'package:epub_view/src/util/mixpanel_manager.dart';
import 'package:flutter/material.dart';

class RecommendItem extends StatelessWidget {
  const RecommendItem({
    super.key,
    required this.tourId,
    required this.baseUrl,
    this.onTourIdSelected,
    required this.attributes,
  });

  final int tourId;
  final String baseUrl;
  final Function(int tourId)? onTourIdSelected;
  final Map<String, String> attributes;

  @override
  Widget build(BuildContext context) {
    final trackTitle = attributes['data-tracktitle'] ?? '';
    final trackContent = attributes['data-content'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.network(attributes['data-creatorimage'] ?? '', width: 32, height: 32, errorBuilder: (context,_,__) {
            return Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle
              ),
            );
          }),
        ),
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
                              onTap: () async {
                                try {
                                  final result = await checkNetworkAndShowDialog(context);
                                  if (result == false) {
                                    return; // 네트워크가 연결되지 않은 경우 함수 종료
                                  }
                                } catch (e) {
                                  // 예외 발생 시 처리
                                  print('네트워크 연결이 필요합니다: $e');
                                  return;
                                }

                                final trackImage = attributes['data-trackimage'] ?? '';
                                final type = attributes['data-type'] ?? 'audio';

                                MixpanelManager.init();
                                MixpanelManager.instance?.track(
                                    'EventOn_PlayAudioFromEbook',
                                    properties: {
                                      'tour_id': tourId.toString(),
                                      'track_title': trackTitle,
                                      'track_id': attributes['data-trackid'] ?? '',
                                    }
                                );

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RecommendContentViewerPage(
                                      baseUrl: baseUrl,
                                      type: type,
                                      epubTourId: tourId.toString(),
                                      trackTourId: attributes['data-tourid'] ?? '',
                                      trackId: attributes['data-trackid'] ?? '',
                                      trackTitle: trackTitle,
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
                                        child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
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
    );
  }

  Future<bool> checkNetworkAndShowDialog(BuildContext context) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    final isConnected = connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;

    if (!isConnected) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: IntrinsicHeight(
              child: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      child: const Column(
                        children: [
                          Text('네트워크에 문제가 있어요', style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          )),
                          SizedBox(height: 8,),
                          Text('Wi-Fi를 사용하거나 데이터 연결이\n되었는지 확인 후 다시 시도해주세요.', style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8A8A8A),
                          )),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              throw Exception('네트워크 연결이 필요합니다.');
                            },
                            child: Container(
                              height: 50,
                              color: const Color(0xFFF9F9F9),
                              child: const Center(
                                child: Text('확인', style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF1A1A1A)
                                )),
                              ),
                            )
                          )
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.of(context).pop();
                              await checkNetworkAndShowDialog(context);
                            },
                            child: Container(
                              height: 50,
                              color: const Color(0xFFFF730D),
                              child: const Center(
                                child: Text('다시 시도하기', style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white
                                )),
                              ),
                            )
                          )
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
      return false; // 네트워크가 연결되지 않은 경우 false 반환
    }
    return true; // 네트워크가 연결된 경우 true 반환
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
