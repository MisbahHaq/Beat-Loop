import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models.dart';
import '../audio_service.dart';
import '../playlist_service.dart';
import '../songs_data.dart';

class Apollo extends StatefulWidget {
  @override
  _ApolloState createState() => _ApolloState();
}

class _ApolloState extends State<Apollo> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  AudioService audioService = AudioService();

  bool _isPlaying = false;
  int _currentSongIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration _songDuration = Duration.zero;
  bool _isLooping = false;
  bool _isShuffling = false;

  List<Playlist> playlists = [];
  List<Song> currentSongs = [];
  bool showingPlaylists = true;
  bool isSearching = false;
  String searchQuery = '';
  List<Song> searchResults = [];

  late LinearGradient currentGradient;

  List<LinearGradient> gradients = [
    LinearGradient(
      colors: [Color(0xFFEEAECA), Color(0xFFEEAECA)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFDBB2D), Color(0xFF3A1C71)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFd53369), Color(0xFFdaae51)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF9F44D3), Color(0xFF9F44D3)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  ];

  void _setCurrentSongIndex(int index) =>
      setState(() => _currentSongIndex = index);
  void _setIsPlaying(bool playing) => setState(() => _isPlaying = playing);
  void _setIsLooping(bool looping) => setState(() => _isLooping = looping);
  void _setIsShuffling(bool shuffling) =>
      setState(() => _isShuffling = shuffling);

  void _playSong(int index) {
    audioService.playSong(index, currentSongs, _setCurrentSongIndex,
        _setIsPlaying, _rotationController);
  }

  void _downloadAllSongsWithProgress(BuildContext context) {
    audioService.downloadAllSongsWithProgress(context, allSongs);
  }

  void _pauseSong() {
    audioService.pauseSong(_setIsPlaying, _rotationController);
  }

  void _resumeSong() {
    audioService.resumeSong(_setIsPlaying, _rotationController);
  }

  void _nextSong() {
    audioService.nextSong(
        _isShuffling, _currentSongIndex, currentSongs, _playSong);
  }

  void _prevSong() {
    audioService.prevSong(
        _isShuffling, _currentSongIndex, currentSongs, _playSong);
  }

  void _toggleLoop() {
    audioService.toggleLoop(_isLooping, _setIsLooping);
  }

  void _toggleShuffle() {
    audioService.toggleShuffle(_isShuffling, _setIsShuffling);
  }

  void _onSeekTap(Offset localPosition, Size size) {
    audioService.onSeekTap(localPosition, size, _songDuration,
        (duration) => audioService.audioPlayer.seek(duration));
  }

  @override
  void initState() {
    super.initState();
    currentGradient = gradients[Random().nextInt(gradients.length)];
    audioService.initializeAudioSession();
    audioService.listenAudioPlayerEvents(
        () => _nextSong(),
        (duration) => setState(() => _currentPosition = duration),
        (duration) => setState(() => _songDuration = duration));
    playlists = PlaylistService.initializePlaylists(allSongs);
    currentSongs = [];

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Song? currentSong =
        currentSongs.isNotEmpty ? currentSongs[_currentSongIndex] : null;

    return Scaffold(
      body: Stack(
        children: [
          if (showingPlaylists) ...[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: currentGradient,
                ),
              ),
            ),
          ],
          if (!showingPlaylists && currentSong != null) ...[
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
                expandedHeight:
                    isSearching ? 0 : MediaQuery.of(context).size.height * 0.6,
                backgroundColor: Colors.transparent,
                title: isSearching
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom:
                                    BorderSide(color: Colors.black, width: 1)),
                          ),
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                                searchResults = allSongs
                                    .where((song) => song.title
                                        .toLowerCase()
                                        .contains(searchQuery))
                                    .toList();
                              });
                            },
                          ),
                        ),
                      )
                    : null,
                leading: !showingPlaylists
                    ? IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            showingPlaylists = true;
                            audioService.audioPlayer.stop();
                            _isPlaying = false;
                            _currentPosition = Duration.zero;
                            _songDuration = Duration.zero;
                          });
                        },
                      )
                    : null,
                actions: showingPlaylists
                    ? [
                        IconButton(
                          icon: Icon(isSearching ? Icons.close : Icons.search,
                              color: Colors.white, size: 30),
                          onPressed: () {
                            setState(() {
                              isSearching = !isSearching;
                              if (!isSearching) {
                                searchQuery = '';
                                searchResults = [];
                              }
                            });
                          },
                        ),
                      ]
                    : !showingPlaylists
                        ? [
                            IconButton(
                              icon: Icon(Icons.download,
                                  color: Colors.white, size: 30),
                              onPressed: () =>
                                  _downloadAllSongsWithProgress(context),
                            ),
                          ]
                        : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.only(top: 80, bottom: 20),
                    child: showingPlaylists
                        ? isSearching
                            ? Container()
                            : Center(
                                child: Text(
                                  "Select a Playlist",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 8,
                                        color: Colors.black54,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (currentSong != null)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final size =
                                        min(constraints.maxWidth * 0.8, 250.0);
                                    return GestureDetector(
                                      onPanDown: (details) => _onSeekTap(
                                          details.localPosition,
                                          Size(size, size)),
                                      onPanUpdate: (details) => _onSeekTap(
                                          details.localPosition,
                                          Size(size, size)),
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
                                                value: _songDuration.inSeconds >
                                                        0
                                                    ? _currentPosition
                                                            .inSeconds /
                                                        _songDuration.inSeconds
                                                    : 0,
                                                strokeWidth: 6,
                                                backgroundColor:
                                                    Colors.grey[800],
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        Colors.white),
                                              ),
                                            ),
                                            AnimatedSwitcher(
                                              duration:
                                                  Duration(milliseconds: 700),
                                              child: RotationTransition(
                                                key:
                                                    ValueKey(currentSong.image),
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
                                      icon: Icon(Icons.loop,
                                          color: _isLooping
                                              ? Colors.blue
                                              : Colors.white),
                                      onPressed: _toggleLoop,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.skip_previous,
                                          color: Colors.white),
                                      onPressed: _prevSong,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                          _isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 40),
                                      onPressed:
                                          _isPlaying ? _pauseSong : _resumeSong,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.skip_next,
                                          color: Colors.white),
                                      onPressed: _nextSong,
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
              showingPlaylists
                  ? isSearching
                      ? searchResults.isEmpty && searchQuery.isNotEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  "Ask Misbah to add the song",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.only(top: 16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final song = searchResults[index];
                                    return ListTile(
                                      textColor: Colors.white,
                                      leading: Image.asset(song.image,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover),
                                      title: Text(song.title),
                                      onTap: () {
                                        setState(() {
                                          currentSongs = [song];
                                          showingPlaylists = false;
                                          isSearching = false;
                                          searchQuery = '';
                                          searchResults = [];
                                          _currentSongIndex = 0;
                                          audioService.audioPlayer.stop();
                                          _isPlaying = false;
                                          _currentPosition = Duration.zero;
                                          _songDuration = Duration.zero;
                                        });
                                        _playSong(0);
                                      },
                                    );
                                  },
                                  childCount: searchResults.length,
                                ),
                              ),
                            )
                      : SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final playlist = playlists[index];
                                String imagePath;
                                switch (playlist.name) {
                                  case 'Hasan Raheem':
                                    imagePath = 'assets/images/has.jpg';
                                    break;
                                  case 'Uzair Jaswal':
                                    imagePath = 'assets/images/uzair.jpg';
                                    break;
                                  case 'All Songs':
                                    imagePath = 'assets/images/shae.jpg';
                                    break;
                                  case 'AMVs':
                                    imagePath = 'assets/images/Gurenge.jpg';
                                    break;
                                  default:
                                    imagePath = 'assets/images/0016.jpg';
                                }
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentSongs = playlist.songs;
                                      showingPlaylists = false;
                                      _currentSongIndex = 0;
                                      audioService.audioPlayer.stop();
                                      _isPlaying = false;
                                      _currentPosition = Duration.zero;
                                      _songDuration = Duration.zero;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: AssetImage(imagePath),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.transparent
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            playlist.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black,
                                                  offset: Offset(1, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: playlists.length,
                            ),
                          ),
                        )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = currentSongs[index];
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
                        childCount: currentSongs.length,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
