import 'package:flutter/material.dart';
import 'package:milife/Services/Apollo.dart';
import 'package:milife/Services/Dot.dart';
import 'package:milife/Services/Less.dart';
import 'package:milife/Services/Tea.dart';
import 'package:milife/Services/Wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MinimalUI extends StatefulWidget {
  const MinimalUI({super.key});

  @override
  _MinimalUIState createState() => _MinimalUIState();
}

class _MinimalUIState extends State<MinimalUI> {
  int selectedIndex = 0;
  List<Map<String, dynamic>> expenses = [];
  int openCount = 0;
  double totalExpense = 0.0;

  final List<String> items = [
    'apollo',
    'less is more',
    'time for tea',
    'fish and chips',
    'dot matrix',
    'back',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedIndex = prefs.getInt('selectedIndex') ?? 0;
      openCount = (prefs.getInt('openCount') ?? 0) + 1;
    });
    prefs.setInt('openCount', openCount);
  }

  Future<void> _updateSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedIndex = index;
    });
    prefs.setInt('selectedIndex', index);
  }

  String getTodayDate() {
    final now = DateTime.now();
    return DateFormat('MMM d').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Removed dark mode feature
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top count and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$openCount',
                        style: TextStyle(
                          fontSize: 64,
                          color: Colors.grey[700], // Set default color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        getTodayDate(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black, // Set default color
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Menu Items
                  ...List.generate(items.length, (index) {
                    return GestureDetector(
                      onTap: () {
                        _updateSelectedIndex(index);
                        if (items[index] == 'fish and chips') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletPage(),
                            ),
                          );
                        } else if (items[index] == 'less is more') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LessIsMore(),
                            ),
                          );
                        } else if (items[index] == 'apollo') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Apollo()),
                          );
                        } else if (items[index] == 'time for tea') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeaPage(),
                            ),
                          );
                        } else if (items[index] == 'dot matrix') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DotMatrix(),
                            ),
                          );
                        } else {
                          _updateSelectedIndex(index);
                        }
                      },
                      child: AnimatedMenuItem(
                        text: items[index],
                        selected: selectedIndex == index,
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedMenuItem extends StatelessWidget {
  final String text;
  final bool selected;

  const AnimatedMenuItem({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    final selectedColor = Colors.black; // Set default color for selected
    final unselectedColor =
        Colors.grey[500]; // Set default color for unselected

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: 28,
              color: selected ? selectedColor : unselectedColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(text),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: selected ? 50 : 0,
            color: selected ? selectedColor : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
