import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class RecommendContentViewerPage extends StatefulWidget {
  const RecommendContentViewerPage({
    super.key,
    required this.type,
    this.imageUrl,
    this.mp3Url,
  });

  final String type;
  final String? imageUrl;
  final String? mp3Url;

  @override
  State<RecommendContentViewerPage> createState() => _RecommendContentViewerPageState();
}

class _RecommendContentViewerPageState extends State<RecommendContentViewerPage> {
  SoLoud? soLoud;
  AudioSource? audioSource;
  SoundHandle? soundHandle;

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'audio') {
      initAudio();
    } else {
      initVideo();
    }
  }

  @override
  void dispose() {
    disposeAudio();
    super.dispose();
  }

  Future<void> disposeAudio() async {
    if (soundHandle != null) {
      await soLoud?.stop(soundHandle!);
      soundHandle = null;
    }
    if (audioSource != null) {
      await soLoud?.disposeSource(audioSource!);
    }
  }

  Future<void> initAudio() async {
    soLoud = SoLoud.instance;
    await soLoud?.init();
    audioSource = await soLoud?.loadUrl(widget.mp3Url ?? '');
  }

  Future<void> initVideo() async {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.mp3Url ?? ''));

    if (videoPlayerController == null) {
      return;
    }

    await videoPlayerController!.initialize();

    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      autoPlay: true,
      aspectRatio: 375.0 / 210.0
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Image.network(widget.imageUrl ?? '', fit: BoxFit.fitHeight, errorBuilder: (context,_,__) {
                    return Container(
                      color: Colors.black,
                    );
                  }),
                ),
              ),
            ),
            Container(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20,),
                        const Expanded(
                          child: Text(
                            'HeaderHeader',
                            style: TextStyle(
                              fontSize: 17,
                              height: 25.0 / 17.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.type == 'video')
                    Expanded(
                      child: Center(
                        child: chewieController != null && chewieController!.videoPlayerController.value.isInitialized ? Chewie(
                          controller: chewieController!,
                        ) : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(60),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(widget.imageUrl ?? '', fit: BoxFit.fitHeight, errorBuilder: (context,_,__) {
                                  return Container(
                                    color: Colors.grey,
                                  );
                                }),
                              )
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: InkWell(
                                onTap: () async {
                                  if (soundHandle != null) {
                                    await soLoud?.stop(soundHandle!);
                                    soundHandle = null;
                                    setState(() {});
                                    return;
                                  }
                                  if (audioSource != null) {
                                    soundHandle = await soLoud?.play(audioSource!);
                                  }
                                  setState(() {});
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      soundHandle == null ? Icons.play_arrow : Icons.stop,
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
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
