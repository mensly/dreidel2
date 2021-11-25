import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dreidel Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Dreidel Game'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  VideoPlayerController? _controller;
  var _loadingStarted = false;
  var _loading = true;
  var _spinning = false;
  var _prevPrevSide = "";
  var _prevSide = "";
  static const _sides = {
    "nun": "נ" + "\nNothing Happens",
    "shin": "ש" + "\nShare into Cup",
    "hay": "ה" + "\nHave a Drink",
    "gimel": "ג" + "\nGet the Cup"
  };

  final _videos = <String, List<String>>{
    "nun": [],
    "nun3": [],
    "shin": [],
    "shin3": [],
    "hay": [],
    "hay3": [],
    "gimel": [],
    "gimel3": [],
  };

  void _loadVideoUrls(AssetBundle bundle) async {
    final manifestContent = await bundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    for (var videoKey in _videos.keys) {
      _videos[videoKey] = manifestMap.keys
          .where((String key) => key.contains('/$videoKey/'))
          .where((String key) => key.contains('.mp4'))
          .toList();
    }
    setState(() {
      _loading = false;
    });
  }

  void _chooseSide() async {
    _controller?.dispose();
    final side = (_sides.keys.toList()..shuffle()).first;
    final video = (_videos[(side == _prevSide && side == _prevPrevSide) ? "${side}3" : side]!
      ..shuffle()).first;
    final controller = VideoPlayerController.asset(video);
    _controller = controller;
    controller.setLooping(false);
    controller.initialize().then((value) => setState(() {}));
    controller.addListener(() {
      if (controller.value.duration.inSeconds > 0) {
        final position = controller.value.position;
        if (position == controller.value.duration) {
          setState(() {
            _spinning = false;
          });
        }
      }
    });

    controller.play();
    setState(() {
      _spinning = true;
      _prevPrevSide = _prevSide;
      _prevSide = side;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadingStarted) {
      _loadingStarted = true;
      _loadVideoUrls(DefaultAssetBundle.of(context));
    }
    final mainChildren = <Widget>[];
    if (_loading) {
      mainChildren.add(const CircularProgressIndicator());
    } else if (_spinning) {
      final controller = _controller;
      if (controller != null) {
        mainChildren.add(AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller)));
      }
    } else {
      mainChildren.add(TextButton(onPressed: () => _chooseSide(), child: const Text("Spin Dreidel", textScaleFactor: 4.0)));
      if (_prevSide.isNotEmpty) {
        mainChildren.add(Text(_sides[_prevSide]!, textAlign: TextAlign.center, textScaleFactor: 10));
      }
      mainChildren.add(const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Game ends when nobody wants to play anymore, someone vomits, someone gets naked, or someone gets engaged.", textAlign: TextAlign.center),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: mainChildren,
        ),
      ),
    );
  }
}
