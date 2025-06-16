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
  List<String> songs = [
    'audio/beloved.mp3',
    'audio/bayaan.mp3',
    'audio/aarzu.mp3',
    'audio/gila.mp3',
    'audio/wishes.mp3',
    'audio/end.mp3',
    'audio/you.mp3',
    'audio/joona.mp3',
    'audio/disconnect.mp3',
    'audio/Zimmedaar.mp3',
    'audio/fursat.mp3',
    'audio/humgama.mp3',
    'audio/escape.mp3',
    'audio/tuhai.mp3',
    'audio/roop.mp3',
    'audio/tra.mp3',
    'audio/tumhiho.mp3',
    'audio/GULABO.mp3',
    'audio/radha.mp3',
    'audio/funka.mp3',
    'audio/memories.mp3',
    'audio/dilkikahani.mp3',
    'audio/endofme.mp3',
    'audio/maya.mp3',
    'audio/turri.mp3',
    'audio/itsover.mp3',
    'audio/raabta.mp3',
    'audio/itachi.mp3',
    'audio/KaisaMai.mp3',
    'audio/tim.mp3',
    'audio/Udjana.mp3',
    'audio/sabrina.mp3',
    'audio/kakashi.mp3',
  ];

  List<String> songNames = [
    'Beloved',
    'Bayaan',
    'Aarzu',
    'Gila',
    'Wishes',
    'End of Heroes',
    'You',
    'Joona',
    'Disconnect',
    'Zimmedaar',
    'Fursat',
    'Hungama',
    'You\'re my Escape',
    'Tu Hai Tou',
    'Roop',
    'In Love With an Angel',
    'Tum hi Ho',
    'Gulabo',
    'Radha',
    'Full Funka',
    'Memories',
    'Dil ki Kahani',
    'End of Me',
    'MayaBee',
    'Turri Jandi',
    'It\'s Not Over',
    'Raabta',
    'Love and Honour',
    'Kaisa Mai',
    'Timmy Turner',
    'Ud Jana',
    'Espresso',
    'Without You',
  ];

  // List of image paths for song album covers
  List<String> songImages = [
    'assets/images/y.jfif',
    'assets/images/bayaan.jpg',
    'assets/images/aarzu.jpg',
    'assets/images/shae.jpg',
    'assets/images/wish.jpg',
    'assets/images/n.jpg',
    'assets/images/joon.jfif',
    'assets/images/has.jpg',
    'assets/images/has.jpg',
    'assets/images/zim.jpg',
    'assets/images/uzair.jpg',
    'assets/images/has.jpg',
    'assets/images/na.png',
    'assets/images/uzair.jpg',
    'assets/images/has.jpg',
    'assets/images/tra.jpg',
    'assets/images/sha.jpg',
    'assets/images/gul.jfif',
    'assets/images/radha.jpg',
    'assets/images/funk.png',
    'assets/images/mem.png',
    'assets/images/uzair.jpg',
    'assets/images/016.jpg',
    'assets/images/maya.jpg',
    'assets/images/tur.jpg',
    'assets/images/shan.jpg',
    'assets/images/r.jfif',
    'assets/images/it.jpg',
    'assets/images/avg.jpg',
    'assets/images/de.jpeg',
    'assets/images/uzair.jpg',
    'assets/images/sab.jpg',
    'assets/images/ka.jpeg',
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
                  fit: BoxFit.contain,
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
