import 'dart:math';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

class _ApolloState extends State<Apollo> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AudioSession _audioSession;
  late AnimationController _rotationController;

  bool _isPlaying = false;
  int _currentSongIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;
  bool _isLooping = false;
  bool _isShuffling = false;

  final List<Song> songs = [
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1758533156/Accusations_gep28z.mp3',
      title: 'Accusations',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718212/flutter_audio_uploads/kwvresbginpk5nymxcss.mp3',
      title: 'Hungama',
      image: 'assets/images/hun.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718158/flutter_audio_uploads/jnal119rxvlnk8wmwsaa.mp3',
      title: 'Gila',
      image: 'assets/images/shae.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718154/flutter_audio_uploads/uanfoccblio4l0mpd72z.mp3',
      title: 'Fursat',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718031/flutter_audio_uploads/oulmx7xjqjpgonrmqw7x.mp3',
      title: 'Aarzu',
      image: 'assets/images/aarzu.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718070/flutter_audio_uploads/efxhz2iefqxzzldtr6g2.mp3',
      title: 'E X E S',
      image: 'assets/images/exes.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718045/flutter_audio_uploads/xbaylg4m1wjz6ovzbs80.mp3',
      title: 'Peanut Butter',
      image: 'assets/images/butter.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718243/flutter_audio_uploads/hewivwsv14j4fgn1mk7f.mp3',
      title: 'Jhol',
      image: 'assets/images/jhol.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718052/flutter_audio_uploads/zsniujekdp6zpry5ix7w.mp3',
      title: 'Dil Ruba',
      image: 'assets/images/dilruba.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718239/flutter_audio_uploads/icwosxltqwljckztj48a.mp3',
      title: 'Jani',
      image: 'assets/images/jani.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1758534975/Faaslay_pdrhtt.mp3',
      title: 'Faaslay',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718377/flutter_audio_uploads/twjmipbdgdhnkbkx9zw1.mp4',
      title: 'Ud Jana',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718074/flutter_audio_uploads/o7ajkztjixdzilaurewj.mp3',
      title: 'Faltu Pyar',
      image: 'assets/images/pyar.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718275/flutter_audio_uploads/lu2cvh66maicstu2yepl.mp3',
      title: 'Maya Bee',
      image: 'assets/images/maya.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718303/flutter_audio_uploads/cnjh3rezvaqfexladsc5.mp3',
      title: 'Piya Calling',
      image: 'assets/images/piya.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1758535340/IDK_g8cnrp.mp3',
      title: 'IDK',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718154/flutter_audio_uploads/uanfoccblio4l0mpd72z.mp3',
      title: 'Tu Hai K Nhi',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718038/flutter_audio_uploads/d109u5y9fvkfgedaoyfm.mp3',
      title: 'Beloved',
      image: 'assets/images/y.jfif',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1758535980/Tareekhi_oq0rq4.mp3',
      title: 'Tareekhi',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718366/flutter_audio_uploads/ckn1qgh2b86utlrppwrb.mp4',
      title: 'Tu Hai Tou',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718035/flutter_audio_uploads/dhhged7ryrlebqsoukuy.mp3',
      title: 'Bayaan',
      image: 'assets/images/bayaan.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1758534815/Lana_Del_Rey_-_West_Coast_whhppw.mp3',
      title: 'West Coast',
      image: 'assets/images/lana.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718387/flutter_audio_uploads/x0iqcxfux9yai0gz75pv.mp3',
      title: 'Wishes',
      image: 'assets/images/wish.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718251/flutter_audio_uploads/jl7vdpo8mujewxdcbs1v.mp3',
      title: 'Kaisa Mein',
      image: 'assets/images/avg.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718392/flutter_audio_uploads/ls41ahrbehlntkxoabf7.mp3',
      title: 'You',
      image: 'assets/images/you.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718048/flutter_audio_uploads/qlisr0o2rzqozncibtpv.mp4',
      title: 'Dil Ki Kahani',
      image: 'assets/images/uzair.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718246/flutter_audio_uploads/aydyma6zz6afvkqww11m.mp3',
      title: 'Joona',
      image: 'assets/images/joon.jfif',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718056/flutter_audio_uploads/pgenxxbgwmifvzpaokgn.mp3',
      title: 'Disconnect',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718396/flutter_audio_uploads/iphtgvyzsbmecqi3f3wf.mp3',
      title: 'Zimmedaar',
      image: 'assets/images/zim.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718369/flutter_audio_uploads/gesvgvnp22fq6na9rewi.mp3',
      title: 'Tum Hi Ho',
      image: 'assets/images/sha.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718374/flutter_audio_uploads/dn4cxjc8aryn4gopewmb.mp3',
      title: 'Turri Jandi',
      image: 'assets/images/tur.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1759051814/Talha_Anjum_-_Departure_Lane___Prod._by_Umair_Official_Music_Video_tclapz.mp3',
      title: 'Departure Lane',
      image: 'assets/images/y.jfif',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1759053650/Bandar_-_Arpit_Bala_X_SangeetKir_kinzko.mp3',
      title: 'Bandar',
      image: 'assets/images/arpit.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718204/flutter_audio_uploads/e4i2ce11x424ato8vsfb.mp3',
      title: 'Gulabo',
      image: 'assets/images/gul.jfif',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1758535262/Fana_gajiyp.mp3',
      title: 'F A N A',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1759053779/Mehbooba_nhfndj.mp3',
      title: 'Mehbooba',
      image: 'assets/images/discon.webp',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718086/flutter_audio_uploads/p4zjewn376yi7n4tztdk.mp3',
      title: 'Full Funka',
      image: 'assets/images/funk.png',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1759051303/Dil_Fareb_kp2pex.mp3',
      title: 'Dil Fareb',
      image: 'assets/images/exes.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718356/flutter_audio_uploads/lcj1rkl7arpc9ybv7ohk.mp3',
      title: 'Roop',
      image: 'assets/images/has.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1759051151/Fana_qpj72r.mp3',
      title: 'Fana',
      image: 'assets/images/you.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718359/flutter_audio_uploads/lavoijbtt3gf8grwuidz.mp3',
      title: 'Timmy Turner',
      image: 'assets/images/de.jpeg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718286/flutter_audio_uploads/h6mshsr6llunvfy3bxo8.mp3',
      title: 'Memories',
      image: 'assets/images/mem.png',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718352/flutter_audio_uploads/smt2hf6i1eqotksmidst.mp3',
      title: 'Radha',
      image: 'assets/images/radha.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1759051478/Kaleji_qgqrhc.mp3',
      title: 'Kaleji',
      image: 'assets/images/exes.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1759051702/JE_KOTA_DIN_TUMI_CHILE_PASHE_FULL_SONG_gdwpy0.mp3',
      title: 'Je Kota Din',
      image: 'assets/images/maya.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718363/flutter_audio_uploads/ianrhclpu6dkel3n615n.mp3',
      title: 'In Love With an Angel',
      image: 'assets/images/tra.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718208/flutter_audio_uploads/nsw89lwoxw5u7andmfrl.mp3',
      title: 'Gurenge',
      image: 'assets/images/Gurenge.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718381/flutter_audio_uploads/lurawunm9lcsqytxnajp.mp3',
      title: 'Unravel',
      image: 'assets/images/Unravel.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718290/flutter_audio_uploads/zr0gowitfof4jid1a8qy.mp3',
      title: 'Namae Yobu',
      image: 'assets/images/namae.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718083/flutter_audio_uploads/hz50ay4i0zrsm6xczurr.mp3',
      title: 'Catch Fire',
      image: 'assets/images/fire.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718060/flutter_audio_uploads/xkoj7qaw86myeponb2f0.mp4',
      title: 'End Of Heroes',
      image: 'assets/images/n.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718063/flutter_audio_uploads/qwdwfwdi2truo8ayotny.mp3',
      title: 'End Of Me',
      image: 'assets/images/shan.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718067/flutter_audio_uploads/xhr5qgaf8ktuuo8obxeu.mp3',
      title: 'Youre My Escape',
      image: 'assets/images/na.png',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718216/flutter_audio_uploads/rmx40qxjarrkrrnlxa43.mp3',
      title: 'Love and Honor',
      image: 'assets/images/it.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718254/flutter_audio_uploads/bfihilwr0qti0zx68cqq.mp3',
      title: 'Call Me Now',
      image: 'assets/images/ka.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718235/flutter_audio_uploads/kisbfqwkoj491bn3rtm1.mp3',
      title: 'Its Not Over',
      image: 'assets/images/0016.jpg',
    ),
    Song(
      path:
          'https://res.cloudinary.com/drcpslfrz/video/upload/v1756718363/flutter_audio_uploads/ianrhclpu6dkel3n615n.mp3',
      title: 'In Love With An Angel',
      image: 'assets/images/tra.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAudioSession();
    _listenAudioPlayerEvents();

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    );
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

    final song = songs[index];
    final file = await _getLocalFile(song);

    // 🔽 If file doesn’t exist, download and show snackbar
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloading ${song.title}..."),
          duration: Duration(seconds: 2),
        ),
      );
      await _downloadFile(song.path, file);
    }

    await _audioPlayer.play(DeviceFileSource(file.path));

    setState(() {
      _isPlaying = true;
      _currentSongIndex = index;
    });

    _rotationController.repeat();
  }

  Future<void> _downloadAllSongsWithProgress(BuildContext context) async {
    // First, count how many need downloading
    int toDownload = 0;
    for (final song in songs) {
      final file = await _getLocalFile(song);
      if (!file.existsSync()) {
        toDownload++;
      }
    }

    if (toDownload == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All songs are already downloaded!')),
      );
      return;
    }

    int completed = 0;
    bool started = false; // ✅ prevent multiple runs

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Start download ONCE
            if (!started) {
              started = true;
              Future(() async {
                for (final song in songs) {
                  final file = await _getLocalFile(song);
                  if (!file.existsSync()) {
                    await _downloadFile(song.path, file);
                    completed++;
                    setDialogState(() {}); // refresh dialog
                  }
                }
                Navigator.of(context).pop(); // close dialog
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All songs downloaded!')),
                  );
                }
              });
            }

            return AlertDialog(
              title: Text("Downloading Songs"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: completed / toDownload),
                  SizedBox(height: 16),
                  Text("Downloading $completed of $toDownload"),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<File> _getLocalFile(Song song, [int? index]) async {
    final dir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = song.title.replaceAll(RegExp(r'[^\w\s]+'), '');
    final extension = song.path.split('.').last.split('?').first;
    final uniquePart = song.path.hashCode.toString();
    final fileName = '${sanitizedTitle}_$uniquePart.$extension';
    return File('${dir.path}/$fileName');
  }

  Future<void> _downloadFile(String url, File file) async {
    try {
      final response = await Dio().download(url, file.path);
      if (response.statusCode == 200) {
        print("Download success: ${file.path}");
      } else {
        print("Download failed with status ${response.statusCode}");
      }
    } catch (e) {
      print("Download error: $e");
    }
  }

  void _pauseSong() {
    _audioPlayer.pause();
    setState(() => _isPlaying = false);
    _rotationController.stop();
  }

  void _resumeSong() {
    _audioPlayer.resume();
    setState(() => _isPlaying = true);
    _rotationController.repeat();
  }

  void _nextSong() {
    if (_isShuffling) {
      int newIndex;
      do {
        newIndex = Random().nextInt(songs.length);
      } while (newIndex == _currentSongIndex && songs.length > 1);
      _playSong(newIndex);
    } else {
      _playSong((_currentSongIndex + 1) % songs.length);
    }
  }

  void _prevSong() {
    if (_isShuffling) {
      int newIndex;
      do {
        newIndex = Random().nextInt(songs.length);
      } while (newIndex == _currentSongIndex && songs.length > 1);
      _playSong(newIndex);
    } else {
      _playSong((_currentSongIndex - 1 + songs.length) % songs.length);
    }
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
    _audioPlayer
        .setReleaseMode(_isLooping ? ReleaseMode.loop : ReleaseMode.release);
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffling = !_isShuffling;
    });
  }

  void _onSeekTap(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > size.width / 2) return;

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    final percent = angle / (2 * pi);
    final seconds =
        (_songDuration.inSeconds * percent).clamp(0, _songDuration.inSeconds);
    _audioPlayer.seek(Duration(seconds: seconds.toInt()));
  }

  @override
  void dispose() {
    _rotationController.dispose();
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
            // 🔹 Background
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: Duration(seconds: 1),
                child: SizedBox.expand(
                  key: ValueKey(currentSong.image),
                  child: Image.asset(
                    currentSong.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ],
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: false,
                expandedHeight: MediaQuery.of(context).size.height * 0.6,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.only(top: 80, bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (currentSong != null)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final size =
                                  min(constraints.maxWidth * 0.8, 250.0);
                              return GestureDetector(
                                onPanDown: (details) => _onSeekTap(
                                    details.localPosition, Size(size, size)),
                                onPanUpdate: (details) => _onSeekTap(
                                    details.localPosition, Size(size, size)),
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
                                              Colors.white),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: Duration(milliseconds: 700),
                                        child: RotationTransition(
                                          key: ValueKey(currentSong.image),
                                          turns: _rotationController,
                                          child: ClipOval(
                                            child: Image.asset(
                                              currentSong.image,
                                              width: size - 30,
                                              height: size - 30,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
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
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 600),
                            child: Text(
                              currentSong.title,
                              key: ValueKey(currentSong.title),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black54,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 20),
                        if (currentSong != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.skip_previous,
                                    color: Colors.white),
                                onPressed: _prevSong,
                              ),
                              IconButton(
                                icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40),
                                onPressed:
                                    _isPlaying ? _pauseSong : _resumeSong,
                              ),
                              IconButton(
                                icon:
                                    Icon(Icons.skip_next, color: Colors.white),
                                onPressed: _nextSong,
                              ),
                              IconButton(
                                icon: Icon(Icons.loop,
                                    color: _isLooping
                                        ? Colors.blue
                                        : Colors.white),
                                onPressed: _toggleLoop,
                              ),
                              IconButton(
                                icon: Icon(Icons.shuffle,
                                    color: _isShuffling
                                        ? Colors.blue
                                        : Colors.white),
                                onPressed: _toggleShuffle,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return ListTile(
                      textColor: Colors.white,
                      leading: Image.asset(song.image,
                          width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(song.title),
                      tileColor: _currentSongIndex == index
                          ? Colors.grey[800]
                          : Colors.transparent,
                      onTap: () => _playSong(index),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ],
          ),
          Positioned(
            top: 30,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.download, color: Colors.white, size: 30),
              onPressed: () async {
                await _downloadAllSongsWithProgress(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
