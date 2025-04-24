import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';

class Apollo extends StatefulWidget {
  @override
  _ApolloState createState() => _ApolloState();
}

class _ApolloState extends State<Apollo> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _currentSongIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;

  // List of songs stored in the assets directory
  List<String> songs = [
    'audio/bts.mp3',
    'audio/escape.mp3',
    'audio/Lucid.mp3',
    "audio/Zimmedaar.mp3",
    "audio/GULABO.mp3",
    "audio/Nindiya.mp3",
    "audio/funka.mp3",
    "audio/dandelions.mp3",
    "audio/kakashi.mp3",
    "audio/tumhiho.mp3",
    "audio/tra.mp3",
    "audio/itachi.mp3",
    "audio/tim.mp3",
    "audio/endofme.mp3",
    "audio/sabrina.mp3",
    "audio/itsover.mp3",
    "audio/kitna.mp3",
    "audio/Katy.mp3",
    "audio/maya.mp3",
    "audio/KaisaMai.mp3",
  ];

  // List of actual song names
  List<String> songNames = [
    'BTS Song',
    'Escape',
    'Lucid',
    'Zimmedaar',
    'GULABO',
    'Nindiya',
    'Funka',
    'Dandelions',
    'Kakashi',
    'Tumhi Ho',
    'Tra',
    'Itachi',
    'Tim',
    'End of Me',
    'Sabrina',
    'It\'s Over',
    'Kitna',
    'Katy',
    'Maya',
    'Kaisa Mai',
  ];

  // List of image paths for song album covers
  List<String> songImages = [
    'assets/images/dan.jpg', // Album cover for BTS song
    'assets/images/dan.jpg', // Album cover for Escape song
    'assets/images/dan.jpg', // Album cover for Lucid song
  ];

  // To handle the audio session (required for background play)
  late AudioSession _audioSession;

  @override
  void initState() {
    super.initState();
    _initializeAudioSession();

    // Listen to when a song finishes
    _audioPlayer.onPlayerComplete.listen((event) {
      _nextSong(); // Automatically play next song when current song finishes
    });

    // Track the current position of the song
    _audioPlayer.onPositionChanged.listen((Duration duration) {
      setState(() {
        _currentPosition = duration;
      });
    });

    // Track the duration of the current song
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _songDuration = duration;
      });
    });
  }

  // Initialize the audio session
  Future<void> _initializeAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(AudioSessionConfiguration.music());
  }

  // Play song
  void _playSong(int index) async {
    if (songs.isNotEmpty && index < songs.length) {
      final song = songs[index];

      // Set audio session to active and handle background playback
      await _audioSession.setActive(true);

      await _audioPlayer.play(AssetSource(song));
      setState(() {
        _isPlaying = true;
        _currentSongIndex = index;
      });
    }
  }

  // Pause song
  void _pauseSong() {
    _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  // Resume song
  void _resumeSong() {
    if (songs.isNotEmpty) {
      final song = songs[_currentSongIndex];
      _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  // Play next song
  void _nextSong() {
    if (songs.isNotEmpty) {
      int nextIndex = (_currentSongIndex + 1) % songs.length;
      _playSong(nextIndex);
    }
  }

  // Play previous song
  void _prevSong() {
    if (songs.isNotEmpty) {
      int prevIndex = (_currentSongIndex - 1 + songs.length) % songs.length;
      _playSong(prevIndex);
    }
  }

  // Seek to a specific position in the song
  void _seekTo(double value) {
    final position = Duration(seconds: value.toInt());
    _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
    _audioSession.setActive(false); // Deactivate session when not needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Song image and controls
          if (songs.isNotEmpty)
            Container(
              width: double.infinity, // Take full width
              height: 250, // Fixed height for the image
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  songImages[_currentSongIndex % songImages.length],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          SizedBox(height: 20),
          if (songs.isNotEmpty)
            Text(
              songNames[_currentSongIndex], // Display the song name instead of file name
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          SizedBox(height: 20),
          if (songs.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: _prevSong,
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: _isPlaying ? _pauseSong : _resumeSong,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: Colors.white),
                  onPressed: _nextSong,
                ),
              ],
            ),
          SizedBox(height: 20),
          // Song Progress Bar
          if (songs.isNotEmpty && _songDuration.inSeconds > 0)
            Slider(
              value:
                  _currentPosition.inSeconds
                      .clamp(0, _songDuration.inSeconds)
                      .toDouble(),
              min: 0,
              max: _songDuration.inSeconds.toDouble(),
              onChanged: (double value) {
                _seekTo(
                  value,
                ); // Seek to the new position when user drags the slider
              },
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
            ),
          SizedBox(height: 20),
          // List of songs in the expanded view
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  textColor: Colors.white,
                  leading: Image.asset(
                    songImages[index % songImages.length],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(songNames[index]), // Display the song name here
                  onTap: () => _playSong(index),
                  tileColor:
                      _currentSongIndex == index
                          ? Colors.grey[800]
                          : Colors.transparent, // Highlight current song
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
