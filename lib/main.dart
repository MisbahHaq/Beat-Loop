import 'package:beatloop/Services/Apollo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:workmanager/workmanager.dart';
import 'download_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintSizeEnabled = false;

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

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
    return MaterialApp(debugShowCheckedModeBanner: false, home: Apollo());
  }
}
