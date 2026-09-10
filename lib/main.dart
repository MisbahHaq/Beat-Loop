import 'package:beatloop/Services/Apollo.dart';
import 'package:beatloop/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:audio_service/audio_service.dart' as a_service;
import 'package:beatloop/beatloop_audio_handler.dart';

BeatLoopAudioHandler? audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintSizeEnabled = false;

  try {
    audioHandler = await a_service.AudioService.init(
      builder: () => BeatLoopAudioHandler(),
      config: const a_service.AudioServiceConfig(
        androidNotificationChannelId: 'com.example.beatloop.channel.audio',
        androidNotificationChannelName: 'Beat Loop',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (e) {
    debugPrint('AudioService init failed: $e');
    audioHandler = null;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: Apollo(),
    );
  }
}