import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';

// Song Model
class Song {
  final String path;
  final String title;
  final String image;
  Song({required this.path, required this.title, required this.image});
}

class Apollo extends StatefulWidget {
  @override
  _ApolloState createState() => _ApolloState();
}

class _ApolloState extends State<Apollo> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AudioSession _audioSession;

  bool _isPlaying = false;
  int _currentSongIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;

  final List<Song> songs = [
    Song(
      path: 'audio/exes.mp3',
      title: 'E X E S',
      image: 'assets/images/exes.jpg',
    ),
    Song(
      path: 'audio/butter.mp3',
      title: 'Peanut Butter',
      image: 'assets/images/butter.jpg',
    ),
    Song(
      path: 'audio/jhol.mp3',
      title: 'Jhol',
      image: 'assets/images/jhol.jpg',
    ),
    Song(
      path: 'audio/dilruba.mp3',
      title: 'Dil Ruba',
      image: 'assets/images/dilruba.jpg',
    ),
    Song(
      path: 'audio/jani.mp3',
      title: 'Jani',
      image: 'assets/images/jani.jpg',
    ),
    Song(
      path: 'audio/faltu.mp3',
      title: 'Faltu Pyar',
      image: 'assets/images/pyar.jpg',
    ),
    Song(
      path: 'audio/piya.mp3',
      title: 'Piya Calling',
      image: 'assets/images/piya.jpg',
    ),
    Song(
      path: 'audio/beloved.mp3',
      title: 'Beloved',
      image: 'assets/images/y.jfif',
    ),
    Song(
      path: 'audio/bayaan.mp3',
      title: 'Bayaan',
      image: 'assets/images/bayaan.jpg',
    ),
    Song(
      path: 'audio/aarzu.mp3',
      title: 'Aarzu',
      image: 'assets/images/aarzu.jpg',
    ),
    Song(
      path: 'audio/gila.mp3',
      title: 'Gila',
      image: 'assets/images/shae.jpg',
    ),
    Song(
      path: 'audio/wishes.mp3',
      title: 'Wishes',
      image: 'assets/images/wish.jpg',
    ),
    Song(path: 'audio/you.mp3', title: 'You', image: 'assets/images/you.jpg'),
    Song(
      path: 'audio/joona.mp3',
      title: 'Joona',
      image: 'assets/images/joon.jfif',
    ),
    Song(
      path: 'audio/disconnect.mp3',
      title: 'Disconnect',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path: 'audio/humgama.mp3',
      title: 'Hungama',
      image: 'assets/images/hun.jpg',
    ),
    Song(
      path: 'audio/fursat.mp3',
      title: 'Fursat',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path: 'audio/Zimmedaar.mp3',
      title: 'Zimmedaar',
      image: 'assets/images/zim.jpg',
    ),
    Song(
      path: 'audio/tuhai.mp3',
      title: 'Tu Hai Tou',
      image: 'assets/images/uzair.jpg',
    ),
    Song(path: 'audio/roop.mp3', title: 'Roop', image: 'assets/images/has.jpg'),
    Song(
      path: 'audio/radha.mp3',
      title: 'Radha',
      image: 'assets/images/radha.jpg',
    ),
    Song(
      path: 'audio/memories.mp3',
      title: 'Memories',
      image: 'assets/images/mem.png',
    ),
    Song(
      path: 'audio/dilkikahani.mp3',
      title: 'Dil Ki Kahani',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path: 'audio/turri.mp3',
      title: 'Turri Jandi',
      image: 'assets/images/tur.jpg',
    ),
    Song(
      path: 'audio/Udjana.mp3',
      title: 'Ud Jana',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path: 'audio/KaisaMai.mp3',
      title: 'Kaisa Mai',
      image: 'assets/images/avg.jpg',
    ),
    Song(
      path: 'audio/tumhiho.mp3',
      title: 'Tum Hi Ho',
      image: 'assets/images/sha.jpg',
    ),
    Song(
      path: 'audio/GULABO.mp3',
      title: 'Gulabo',
      image: 'assets/images/gul.jfif',
    ),
    Song(
      path: 'audio/funka.mp3',
      title: 'Full Funka',
      image: 'assets/images/funk.png',
    ),
    Song(
      path: 'audio/end.mp3',
      title: 'End of Heroes',
      image: 'assets/images/n.jpg',
    ),
    Song(
      path: 'audio/escape.mp3',
      title: 'You\'re my Escape',
      image: 'assets/images/na.png',
    ),
    Song(
      path: 'audio/tra.mp3',
      title: 'In Love With an Angel',
      image: 'assets/images/tra.jpg',
    ),
    Song(
      path: 'audio/endofme.mp3',
      title: 'End of Me',
      image: 'assets/images/0016.jpg',
    ),
    Song(
      path: 'audio/maya.mp3',
      title: 'MayaBee',
      image: 'assets/images/maya.jpg',
    ),
    Song(
      path: 'audio/itsover.mp3',
      title: 'It\'s Not Over',
      image: 'assets/images/shan.jpg',
    ),
    Song(
      path: 'audio/raabta.mp3',
      title: 'Raabta',
      image: 'assets/images/r.jfif',
    ),
    Song(
      path: 'audio/itachi.mp3',
      title: 'Love and Honour',
      image: 'assets/images/it.jpg',
    ),
    Song(
      path: 'audio/tim.mp3',
      title: 'Timmy Turner',
      image: 'assets/images/de.jpeg',
    ),
    Song(
      path: 'audio/kakashi.mp3',
      title: 'Without You',
      image: 'assets/images/ka.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAudioSession();
    _listenAudioPlayerEvents();
  }

  Future<void> _initializeAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(AudioSessionConfiguration.music());
  }

  void _listenAudioPlayerEvents() {
    _audioPlayer.onPlayerComplete.listen((_) => _nextSong());
    _audioPlayer.onPositionChanged.listen((duration) {
      setState(() => _currentPosition = duration);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _songDuration = duration);
    });
  }

  Future<void> _playSong(int index) async {
    if (songs.isEmpty || index >= songs.length) return;

    await _audioSession.setActive(true);
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(songs[index].path));

    setState(() {
      _isPlaying = true;
      _currentSongIndex = index;
    });
  }

  void _pauseSong() {
    _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _resumeSong() {
    _audioPlayer.resume();
    setState(() => _isPlaying = true);
  }

  void _nextSong() => _playSong((_currentSongIndex + 1) % songs.length);
  void _prevSong() =>
      _playSong((_currentSongIndex - 1 + songs.length) % songs.length);

  void _onSeekTap(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > size.width / 2) return;

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    final percent = angle / (2 * pi);
    final seconds = (_songDuration.inSeconds * percent).clamp(
      0,
      _songDuration.inSeconds,
    );
    _audioPlayer.seek(Duration(seconds: seconds.toInt()));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioSession.setActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Song? currentSong =
        songs.isNotEmpty ? songs[_currentSongIndex] : null;

    return Scaffold(
      body: Stack(
        children: [
          if (currentSong != null) ...[
            Positioned.fill(
              child: Image.asset(currentSong.image, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                SizedBox(height: 20),
                if (currentSong != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final size = min(constraints.maxWidth, 300.0);
                      return GestureDetector(
                        onPanDown: (details) =>
                            _onSeekTap(details.localPosition, Size(size, size)),
                        onPanUpdate: (details) =>
                            _onSeekTap(details.localPosition, Size(size, size)),
                        child: Container(
                          width: size,
                          height: size,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: size,
                                height: size,
                                child: CircularProgressIndicator(
                                  value: _songDuration.inSeconds > 0
                                      ? _currentPosition.inSeconds /
                                          _songDuration.inSeconds
                                      : 0,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              ClipOval(
                                child: Image.asset(
                                  currentSong.image,
                                  width: size - 30,
                                  height: size - 30,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                SizedBox(height: 20),
                if (currentSong != null)
                  Text(
                    currentSong.title,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                SizedBox(height: 20),
                if (currentSong != null)
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
                      final song = songs[index];
                      return ListTile(
                        textColor: Colors.white,
                        leading: Image.asset(
                          song.image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(song.title),
                        tileColor: _currentSongIndex == index
                            ? Colors.grey[800]
                            : Colors.transparent,
                        onTap: () => _playSong(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
