import 'package:flutter/material.dart';
import 'package:milife/Services/Less.dart';
import 'package:milife/Services/Tea.dart';
import 'package:milife/Services/Wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MinimalUI extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const MinimalUI({required this.isDark, required this.onToggleTheme});

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
    final isDark = widget.isDark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
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
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        getTodayDate(),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
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
                        } else if (items[index] == 'time for tea') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeaPage(),
                            ),
                          );
                        } else {
                          _updateSelectedIndex(index);
                        }
                      },
                      child: AnimatedMenuItem(
                        text: items[index],
                        selected: selectedIndex == index,
                        isDark: isDark,
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Bottom right theme toggle
            Positioned(
              bottom: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: widget.onToggleTheme,
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
  final bool isDark;

  const AnimatedMenuItem({
    required this.text,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? Colors.white : Colors.black;
    final unselectedColor = isDark ? Colors.grey[600] : Colors.grey[500];

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
