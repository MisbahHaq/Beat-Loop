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

  // List of songs stored in the assets directory
  List<String> songs = ['audio/bts.mp3', 'audio/escape.mp3', 'audio/Lucid.mp3'];

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
  }

  // Initialize the audio session
  Future<void> _initializeAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(AudioSessionConfiguration.music());
  }

  // Play song
  void _playSong(int index) async {
    if (songs.isNotEmpty) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (songs.isNotEmpty)
              Container(
                width: 250,
                height: 250,
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
                    songImages[_currentSongIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SizedBox(height: 30),
            if (songs.isNotEmpty)
              Text(
                '${songs[_currentSongIndex].split('/').last}',
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
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    textColor: Colors.white,
                    leading: Image.asset(
                      songImages[index],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text('Song ${index + 1}'),
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
      ),
    );
  }
}
