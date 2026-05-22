import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webinar/common/utils/date_formater.dart';
import 'package:webinar/common/utils/download_manager.dart';
import 'package:webinar/config/assets.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';

import '../../../../../common/common.dart';

class CourseVideoPlayer extends StatefulWidget {
  final String url;
  final String imageCover;
  
  final bool isLoadNetwork;
  final String? localFileName;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const CourseVideoPlayer(this.url, this.imageCover,this.routeObserver, {this.isLoadNetwork = true, this.localFileName, super.key});
  

  @override
  State<CourseVideoPlayer> createState() => _CourseVideoPlayerState();
}

class _CourseVideoPlayerState extends State<CourseVideoPlayer>  with RouteAware {

  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  bool isShowPlayButton=false;
  bool isPlaying=true;

  Duration videoDuration = const Duration(seconds: 0);
  Duration videoPosition = const Duration(seconds: 0);


  // bool isShowVideoPlayer = false;

  @override
  void initState() {
    super.initState();
    initVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);

    (player.platform as dynamic).setProperty('cache', 'yes'); // --cache=<yes|no|auto>
    (player.platform as dynamic).setProperty('cache-secs', '5'); // --cache-secs=<seconds> with cache but why not.
    (player.platform as dynamic).setProperty('demuxer-donate-buffer', 'yes');
    (player.platform as dynamic).setProperty('force-seekable','yes');
    (player.platform as dynamic).setProperty('demuxer-seekable-cache', 'auto');
  }


  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    player.dispose();
    super.dispose();
  }

  @override
  void didPush() {}

  @override
  void didPushNext() {
    // final route = ModalRoute.of(context)?.settings.name;
    player.pause();
  } 

  @override
  void didPopNext() {
    player.play();
  }


  initVideo() async {
    
    if(widget.isLoadNetwork){
      
      // controller = VideoPlayerController.networkUrl(
      //   Uri.parse(widget.url),
      // )..initialize().then((_) {
        
      //   isShowVideoPlayer = true;
        
      //   controllerListener();
      //   setState(() {});
      //   controller.play();
      // });
      
      player.open(Media(widget.url));

    }else{
      
      String directory = (await getApplicationSupportDirectory()).path;
      print('${directory.toString()}/${widget.localFileName}');
      
      bool isExistFile = await DownloadManager.findFile(directory, widget.localFileName!,isOpen: false);


      if(isExistFile){

        player.open(Media('${directory.toString()}/${widget.localFileName}'));

        // controller = VideoPlayerController.file(
        //   File('${directory.toString()}/${widget.localFileName}'),
        // )..initialize().then((_) {
        //   isShowVideoPlayer = true;

        //   controllerListener();
        //   setState(() {});
        //   controller.play();
        // });
      }
    }

  }

  controllerListener(){

    player.stream.position.listen((event) {
      if(videoPosition.inSeconds != event.inSeconds){

        setState(() {
          videoPosition = Duration(seconds: event.inSeconds);
        });
      }
    });

    player.stream.duration.listen((event) {
      if(videoDuration.inSeconds != event.inSeconds){
        setState(() {
          videoDuration = Duration(seconds: event.inSeconds);
        });
      }
    });


  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // video
        // if(isShowVideoPlayer)...{
          ClipRRect(
            borderRadius: borderRadius(),
            child: Column(
              children: [

                AspectRatio(
                  aspectRatio: 16 / 9.0,
                  child: Video(controller: controller),
                ),


              ],
            )
          
          ),
        
          space(12),

          AnimatedCrossFade(

            firstChild: Container(
              padding: padding(horizontal: 16,vertical: 16),
              width: getSize().width,
              decoration: BoxDecoration(
                color: whiteFF_26,
                borderRadius: borderRadius()
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // duration and play button
                  Row(
                    children: [

                      GestureDetector(
                        onTap: (){
                          if(isPlaying){
                            player.pause();
                          }else{
                            player.play();
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: greyB2,
                            )
                          ),
                          child: Icon(!isPlaying ? Icons.play_arrow_rounded : Icons.pause, size: 17, color: greyB2,),
                        ),
                      ),

                      space(0,width: 16),
                      
                      Text(
                        '${secondDurationToString(videoPosition.inSeconds)} / ${secondDurationToString(videoDuration.inSeconds)}',
                        style: style12Regular().copyWith(color: greyB2),
                      ),

                    ],
                  ),



                  Row(
                    children: [
                      
                      // sound
                      GestureDetector(
                        onTap: (){
                          if(player.state.volume == 0.0){
                            player.setVolume(1.0);
                          }else{
                            player.setVolume(0.0);
                          }

                          setState(() {});
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SvgPicture.asset(
                          player.state.volume == 0.0 ? AppAssets.soundOffSvg : AppAssets.soundOnSvg
                        ),
                      ),

                      // space(0,width: 22),

                      // // full screen
                      // GestureDetector(
                      //   onTap: () async {
                      //     player.pause();
                          
                      //     // await navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => FullScreenVideoPlayer(controller)));

                      //     SystemChrome.setPreferredOrientations([
                      //       DeviceOrientation.portraitUp,
                      //     ]);
                      //   },
                      //   behavior: HitTestBehavior.opaque,
                      //   child: SvgPicture.asset(
                      //     AppAssets.fullscreenSvg
                      //   ),
                      // ),

                    ],
                  )

                ],
              ),

            ), 

            secondChild: SizedBox(width: getSize().width), 
            crossFadeState: CrossFadeState.showFirst, 
            duration: const Duration(milliseconds: 300)
          )
        
        // },


      ],
    );
  }



}