import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';

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

  final List<String> songs = [
    'audio/butter.mp3',
    'audio/dilruba.mp3',
    'audio/jani.mp3',
    'audio/faltu.mp3',
    'audio/beloved.mp3',
    'audio/bayaan.mp3',
    'audio/aarzu.mp3',
    'audio/gila.mp3',
    'audio/wishes.mp3',
    'audio/you.mp3',
    'audio/joona.mp3',
    'audio/disconnect.mp3',
    'audio/humgama.mp3',
    'audio/fursat.mp3',
    'audio/Zimmedaar.mp3',
    'audio/tuhai.mp3',
    'audio/roop.mp3',
    'audio/radha.mp3',
    'audio/memories.mp3',
    'audio/dilkikahani.mp3',
    'audio/turri.mp3',
    'audio/Udjana.mp3',
    'audio/KaisaMai.mp3',
    'audio/tumhiho.mp3',
    'audio/GULABO.mp3',
    'audio/funka.mp3',
    'audio/end.mp3',
    'audio/escape.mp3',
    'audio/tra.mp3',
    'audio/endofme.mp3',
    'audio/maya.mp3',
    'audio/itsover.mp3',
    'audio/raabta.mp3',
    'audio/itachi.mp3',
    'audio/tim.mp3',
    'audio/sabrina.mp3',
    'audio/kakashi.mp3',
  ];

  final List<String> songNames = [
    'Peanut Butter',
    'Dil Ruba',
    'Jani',
    'Faltu Pyar',
    'Beloved',
    'Bayaan',
    'Aarzu',
    'Gila',
    'Wishes',
    'You',
    'Joona',
    'Disconnect',
    'Hungama',
    'Fursat',
    'Zimmedaar',
    'Tu Hai Tou',
    'Roop',
    'Radha',
    'Memories',
    'Dil ki Kahani',
    'Turri Jandi',
    'Ud Jana',
    'Kaisa Mai',
    'Tum hi Ho',
    'Gulabo',
    'Full Funka',
    'End of Heroes',
    'You\'re my Escape',
    'In Love With an Angel',
    'End of Me',
    'MayaBee',
    'It\'s Not Over',
    'Raabta',
    'Love and Honour',
    'Timmy Turner',
    'Espresso',
    'Without You',
  ];

  final List<String> songImages = [
    'assets/images/butter.jpg',
    'assets/images/joon.jfif',
    'assets/images/jani.jpg',
    'assets/images/pyar.jpg',
    'assets/images/y.jfif',
    'assets/images/bayaan.jpg',
    'assets/images/aarzu.jpg',
    'assets/images/shae.jpg',
    'assets/images/wish.jpg',
    'assets/images/discon.webp',
    'assets/images/joon.jfif',
    'assets/images/discon.webp',
    'assets/images/has.jpg',
    'assets/images/uzair.jpg',
    'assets/images/zim.jpg',
    'assets/images/uzair.jpg',
    'assets/images/has.jpg',
    'assets/images/radha.jpg',
    'assets/images/mem.png',
    'assets/images/uzair.jpg',
    'assets/images/tur.jpg',
    'assets/images/uzair.jpg',
    'assets/images/avg.jpg',
    'assets/images/sha.jpg',
    'assets/images/gul.jfif',
    'assets/images/funk.png',
    'assets/images/n.jpg',
    'assets/images/na.png',
    'assets/images/tra.jpg',
    'assets/images/016.jpg',
    'assets/images/maya.jpg',
    'assets/images/shan.jpg',
    'assets/images/r.jfif',
    'assets/images/it.jpg',
    'assets/images/de.jpeg',
    'assets/images/sab.jpg',
    'assets/images/ka.jpeg',
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
    await _audioPlayer.setPlaybackRate(1.0);
    await _audioPlayer.play(AssetSource(songs[index]));

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
    final bgImage =
        songs.isNotEmpty
            ? songImages[_currentSongIndex % songImages.length]
            : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (bgImage != null) ...[
            Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.cover)),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ],
          Column(
            children: [
              SizedBox(height: 20),
              if (songs.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = min(constraints.maxWidth, 300.0);
                    return GestureDetector(
                      onPanDown:
                          (details) => _onSeekTap(
                            details.localPosition,
                            Size(size, size),
                          ),
                      onPanUpdate:
                          (details) => _onSeekTap(
                            details.localPosition,
                            Size(size, size),
                          ),
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
                                value:
                                    _songDuration.inSeconds > 0
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
                                songImages[_currentSongIndex %
                                    songImages.length],
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
              if (songs.isNotEmpty)
                Text(
                  songNames[_currentSongIndex],
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
                  itemBuilder:
                      (context, index) => ListTile(
                        textColor: Colors.white,
                        leading: Image.asset(
                          songImages[index % songImages.length],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(songNames[index]),
                        tileColor:
                            _currentSongIndex == index
                                ? Colors.grey[800]
                                : Colors.transparent,
                        onTap: () => _playSong(index),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
