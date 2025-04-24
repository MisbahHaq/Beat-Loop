import 'package:flutter/material.dart';

class LessIsMore extends StatefulWidget {
  const LessIsMore({super.key});

  @override
  State<LessIsMore> createState() => _LessIsMoreState();
}

class _LessIsMoreState extends State<LessIsMore> {
  final List<String> quotes = [
    "Dirty Deeds Done Dirt Cheap",
    "Believe you can and you're halfway there.",
    "To defeat Evil, I shal become an even greater Evil",
    "The best time to plant a tree was 20 years ago.",
    "What a fucking Nigger...",
    "We were Pokemons all this time, waiting for people to choose us.",
    "You're a lady as ephemeral and elegant as a lotus blossom.",
    "Feel what you need to feel, then let it go. Don't let it consume you.",
    "And I knew exactly what to do, but in a much more real sense, I had no idea what to do.",
    "Ohh Little one, I don't wanna admit to something, if all it's gonna cause is pain; Truth in my lies right now are falling like the rain, so let the river run.",
    "Softly let's have a break.",
    "Love made me feel I knew the answer, but when I raised my hand I was the only one in the room.",
    "Someone has to leave first. This is a very old story. There is no other version of it.",
    "Remember kids, Don't use drugs.",
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
