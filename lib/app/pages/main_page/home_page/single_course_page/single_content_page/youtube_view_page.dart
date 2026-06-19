import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/youtube_direct_player.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/utils/constants.dart';

class YoutubeViewPage extends StatefulWidget {
  static const String pageName = '/youtube-view';
  const YoutubeViewPage({super.key});

  @override
  State<YoutubeViewPage> createState() => _YoutubeViewPageState();
}

class _YoutubeViewPageState extends State<YoutubeViewPage> {
  String? videoId;
  String? title;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final args = ModalRoute.of(context)!.settings.arguments as List;
      videoId = args[0];
      title = args[1] ?? '';
      setState(() {});
    });
  }

  Future<void> _onExitFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onExitFullscreen();
        }
      },
      child: directionality(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: null,
          body: videoId != null
              ? YoutubeDirectPlayer(
                  videoId!,
                  Constants.contentRouteObserver,
                  onExitTap: _onExitFullscreen,
                  isLandscape: true,
                )
              : const SizedBox(),
        ),
      ),
    );
  }
}
