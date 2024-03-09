import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:player/m_player.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  String source = 'playboy.player';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // change the demo app color
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo, brightness: Brightness.dark),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MPlayer(title: source),
      ),
    );
  }
}
