import 'package:flutter/material.dart';
import 'package:milife/Home/HomePage.dart';
import 'package:milife/OnBoarding/Login.dart';
import 'package:milife/Services/Less.dart';
import 'package:milife/Services/Tea.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool('isDark') ?? false;
    });
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDark = !isDark);
    prefs.setBool('isDark', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      // home: MinimalUI(isDark: isDark, onToggleTheme: _toggleTheme),
      home: LoginPage(onToggleTheme: _toggleTheme),
    );
  }
}
