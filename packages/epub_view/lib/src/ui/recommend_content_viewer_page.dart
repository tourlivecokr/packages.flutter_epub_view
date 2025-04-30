import 'package:flutter/material.dart';

class RecommendContentViewerPage extends StatefulWidget {
  const RecommendContentViewerPage({
    super.key,
    this.imageUrl,
    this.mp3Url,
  });

  final String? imageUrl;
  final String? mp3Url;

  @override
  State<RecommendContentViewerPage> createState() => _RecommendContentViewerPageState();
}

class _RecommendContentViewerPageState extends State<RecommendContentViewerPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Stack(
          children: [
            Container(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20,),
                        Expanded(
                          child: Text(
                            'HeaderHeader',
                            style: TextStyle(
                              fontSize: 17,
                              height: 25.0 / 17.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(60),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(widget.imageUrl ?? '', errorBuilder: (context,_,__) {
                                return Container(
                                  color: Colors.grey,
                                );
                              }),
                            )
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: () {

                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.black.withOpacity(0.6),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                )
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TitleTitleTitleTitleTitleTitle',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 22.0 / 16.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '50,000원',
                                    style: TextStyle(
                                      fontSize: 18,
                                      height: 26.0 / 18.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  )
                                ],
                              )
                            ),
                            const SizedBox(width: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network('', width: 70, height: 70, errorBuilder: (context,_,__) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey,
                                );
                              }),
                            )
                          ],
                        ),
                        const SizedBox(height: 15,),
                        InkWell(
                          onTap: () {

                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xffFF730D),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                '셀프투어가 궁금하다면 클릭 👉',
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 22.0 / 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
