import 'package:flutter/material.dart';

class LessIsMore extends StatefulWidget {
  const LessIsMore({super.key});

  @override
  State<LessIsMore> createState() => _LessIsMoreState();
}

class _LessIsMoreState extends State<LessIsMore> {
  final List<String> quotes = [
    "Success is not final, failure is not fatal.",
    "Believe you can and you're halfway there.",
    "Your time is limited, don’t waste it.",
    "The best time to plant a tree was 20 years ago.",
    "What a fucking Nigger",
  ];

  String currentQuote = "";

  @override
  void initState() {
    super.initState();
    currentQuote = _getRandomQuote();
  }

  String _getRandomQuote() {
    return quotes[DateTime.now().millisecondsSinceEpoch % quotes.length];
  }

  void _getNewQuote() {
    setState(() {
      currentQuote = _getRandomQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote text replacing "Skibidi"
              Padding(
                padding: const EdgeInsets.only(top: 300),
                child: Text(
                  currentQuote,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _getNewQuote,
                child: const Text(
                  "again",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "quit",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
