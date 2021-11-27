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
        primarySwatch: const Color(0xff003f9a).toMaterialColor(),
      ),
      home: const MyHomePage(title: 'Dreidel Drinking Game'),
    );
  }
}

extension ColorExtension on Color {
  MaterialColor toMaterialColor() {
    Map<int, Color> color = {
      50: withOpacity(.1),
      100: withOpacity(.2),
      200: withOpacity(.3),
      300: withOpacity(.4),
      400: withOpacity(.5),
      500: withOpacity(.6),
      600: withOpacity(.7),
      700: withOpacity(.8),
      800: withOpacity(.9),
      900: withOpacity(1.0),
    };
    return MaterialColor(value, color);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _rules = [
    "Players take turns to spin the dreidel, with what it lands on determining the outcome. ",
    "There is a cup in the middle.",
    "",
    "• " "נ" " Nun — NOTHING happens",
    "• " "ה" " Hay — HAVE a drink",
    "• " "ש" " Shin — SHARE a drink into the cup",
    "• " "ג" " Gimel — GET the cup, and down it",
    "",
    "A full-cup "
        "ש"
        " counts as a "
        "ג"
        " and an empty-cup "
        "ג"
        " counts as a "
        "ש"
        ".",
    "",
    "• Three "
        "נ"
        "'s in a row — Those three players must finish their drinks.",
    "• Three " "ה" "'s in a row — Everyone in the game has a drink",
    "• Three "
        "ש"
        "'s in a row — Those three pour into the cup until it is full or their drink is empty",
    "• Three " "ג" "'s in a row — Those three remove an item of clothing each",
    "",
    "Game ends when someone vomits or gets naked or engaged, players swapping in and out is fine.",
    "",
    "No scarves allowed, any children resulting from this game should be raised Jewish."
  ];
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
    final video = (_videos[
            (side == _prevSide && side == _prevPrevSide) ? "${side}3" : side]!
          ..shuffle())
        .first;
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

  void _showRules(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text("Dreidel Drinking Game Rules"),
              content: SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _rules.map((e) => Text(e)).toList(),
              )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"))
              ],
            ));
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
      mainChildren.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton(
            onPressed: () => _chooseSide(),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Spin Dreidel", textScaleFactor: 4.0),
            )),
      ));
      if (_prevSide.isNotEmpty) {
        mainChildren.add(Text(_sides[_prevSide]!,
            textAlign: TextAlign.center, textScaleFactor: 8));
      }
      mainChildren.add(const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
            "Game ends when nobody wants to play anymore, someone vomits, someone gets naked, or someone gets engaged.",
            textAlign: TextAlign.center),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () => _showRules(context),
                child: const Icon(
                  Icons.rule_folder,
                  size: 26.0,
                ),
              )),
        ],
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
