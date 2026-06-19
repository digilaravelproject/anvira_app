import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;

import '../../../../../config/colors.dart';
import '../../../../../config/styles.dart';

class YoutubeDirectPlayer extends StatefulWidget {
  final String videoId;
  final RouteObserver<ModalRoute<void>> routeObserver;
  final VoidCallback? onExitTap;
  final bool isLandscape;

  const YoutubeDirectPlayer(
    this.videoId,
    this.routeObserver, {
    super.key,
    this.onExitTap,
    this.isLandscape = false,
  });

  @override
  State<YoutubeDirectPlayer> createState() => _YoutubeDirectPlayerState();
}

class _YoutubeDirectPlayerState extends State<YoutubeDirectPlayer>
    with RouteAware {
  final yt = YoutubeExplode();
  final player = Player();
  late final controller = VideoController(player);

  bool isLoading = true;
  String? errorMsg;
  bool isPlaying = false;
  bool showControls = false;
  Duration videoPosition = Duration.zero;
  Duration videoDuration = Duration.zero;

  StreamSubscription? positionSub;
  StreamSubscription? durationSub;
  StreamSubscription? playingSub;
  Timer? hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _loadVideo();
    _setupListeners();
  }

  void _setupListeners() {
    positionSub = player.stream.position.listen((event) {
      if (videoPosition.inSeconds != event.inSeconds) {
        setState(() {
          videoPosition = Duration(seconds: event.inSeconds);
        });
      }
    });

    durationSub = player.stream.duration.listen((event) {
      if (videoDuration.inSeconds != event.inSeconds) {
        setState(() {
          videoDuration = Duration(seconds: event.inSeconds);
        });
      }
    });

    playingSub = player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          isPlaying = playing;
          if (playing) {
            showControls = true;
            _startHideTimer();
          }
        });
      }
    });
  }

  void _onTapVideo() {
    setState(() {
      showControls = !showControls;
    });
    if (showControls) {
      _startHideTimer();
    } else {
      hideControlsTimer?.cancel();
    }
  }

  void _startHideTimer() {
    hideControlsTimer?.cancel();
    if (isPlaying) {
      hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showControls = false;
          });
        }
      });
    }
  }

  void _togglePlayPause() {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    _startHideTimer();
  }

  void _onSliderChanged(double value) {
    player.seek(Duration(seconds: value.toInt()));
  }

  void _onSliderChangeStart(double value) {
    hideControlsTimer?.cancel();
  }

  void _onSliderChangeEnd(double value) {
    _startHideTimer();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _loadVideo() async {
    try {
      final url = 'https://www.youtube.com/watch?v=${widget.videoId}';
      final manifest = await yt.videos.streamsClient.getManifest(url);
      final streamInfo = manifest.muxed.withHighestBitrate();
      final streamUrl = streamInfo.url.toString();
      await player.open(Media(streamUrl));
      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = e.toString();
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
    (player.platform as dynamic).setProperty('osc', 'no');
    (player.platform as dynamic).setProperty('osd-level', '0');
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    yt.close();
    player.dispose();
    positionSub?.cancel();
    durationSub?.cancel();
    playingSub?.cancel();
    hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  void didPush() {}

  @override
  void didPushNext() {
    player.pause();
  }

  @override
  void didPopNext() {
    player.play();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = green77();

    return Container(
      color: Colors.black,
      child: Builder(
        builder: (context) {
          if (errorMsg != null) {
            return Center(
              child: Text(
                'Video load error',
                style: style14Regular().copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return GestureDetector(
            onTap: _onTapVideo,
            child: Stack(
              children: [
                Video(controller: controller),

                if (showControls)
                  Positioned.fill(
                    child: Container(color: Colors.black26),
                  ),

                if (!isPlaying && !showControls)
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                if (showControls) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 16, bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              activeTrackColor: primaryColor,
                              inactiveTrackColor: Colors.white38,
                              thumbColor: primaryColor,
                              thumbShape:
                                  const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayColor:
                                  primaryColor.withValues(alpha: 0.2),
                              overlayShape:
                                  const RoundSliderOverlayShape(overlayRadius: 14),
                            ),
                            child: Slider(
                              value: videoDuration.inSeconds > 0
                                  ? videoPosition.inSeconds.toDouble()
                                  : 0,
                              max: videoDuration.inSeconds > 0
                                  ? videoDuration.inSeconds.toDouble()
                                  : 1,
                              onChanged: _onSliderChanged,
                              onChangeStart: _onSliderChangeStart,
                              onChangeEnd: _onSliderChangeEnd,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _togglePlayPause,
                                child: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${_formatDuration(videoPosition)} / ${_formatDuration(videoDuration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'SF-Pro-Regular',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: widget.onExitTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
