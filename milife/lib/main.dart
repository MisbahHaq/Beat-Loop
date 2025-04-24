import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:milife/Home/HomePage.dart';
import 'package:milife/OnBoarding/Login.dart';
import 'package:milife/Services/Apollo.dart';

void main() {
  debugPaintSizeEnabled = false;
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
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage());
  }
}
