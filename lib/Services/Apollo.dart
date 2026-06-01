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
  List<Song> recentlyPlayed = [];

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

  void _playSong(int index) async {
    try {
      await audioService.playSong(index, currentSongs, _setCurrentSongIndex,
          _setIsPlaying, _rotationController);
      // Track recently played songs
      final song = currentSongs[index];
      setState(() {
        recentlyPlayed.removeWhere(
            (s) => s.title == song.title && s.artist == song.artist);
        recentlyPlayed.insert(0, song);
        if (recentlyPlayed.length > 10) {
          recentlyPlayed = recentlyPlayed.take(10).toList();
        }
      });
    } catch (e) {
      // Silent error handling
    }
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

  Widget _buildGenreTab(String label, String count, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.3)),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    currentGradient = LinearGradient(
      colors: [Colors.black, Colors.black],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    audioService.initializeAudioSession();
    audioService.listenAudioPlayerEvents(() {
      print(
          "DEBUG: onPlayerComplete triggered. Current position: ${_currentPosition.inSeconds}s, Song duration: ${_songDuration.inSeconds}s, Song: ${currentSongs.isNotEmpty ? currentSongs[_currentSongIndex].title : 'N/A'}");
      _nextSong();
    }, (duration) {
      setState(() => _currentPosition = duration);
      // Log position every 30 seconds to avoid spam
      if (duration.inSeconds % 30 == 0 && duration.inSeconds > 0) {
        print(
            "DEBUG: Playback position: ${duration.inSeconds}s / ${_songDuration.inSeconds}s");
      }
    }, (duration) {
      setState(() => _songDuration = duration);
      print("DEBUG: Song duration set to: ${duration.inSeconds} seconds");
    });
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

    return WillPopScope(
      onWillPop: () async {
        if (!showingPlaylists) {
          setState(() {
            showingPlaylists = true;
          });
          return false; // Prevent popping the route
        }
        return true; // Allow popping if already on playlists view
      },
      child: Scaffold(
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
            Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: false,
                      floating: false,
                      expandedHeight: isSearching
                          ? 0
                          : MediaQuery.of(context).size.height * 0.6,
                      backgroundColor: Colors.transparent,
                      title: isSearching
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.black, width: 1)),
                                ),
                                child: TextField(
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
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
                                });
                              },
                            )
                          : null,
                      actions: showingPlaylists
                          ? [
                              IconButton(
                                icon: Icon(
                                    isSearching ? Icons.close : Icons.search,
                                    color: Colors.white,
                                    size: 30),
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
                                  : Column(
                                      children: [
                                        SizedBox(height: 40),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Your Library",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            "Playlists",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Container(
                                          height: 130,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: playlists.length,
                                            itemBuilder: (context, index) {
                                              final playlist = playlists[index];
                                              String imagePath;
                                              switch (playlist.name) {
                                                case 'Hasan Raheem':
                                                  imagePath =
                                                      'assets/images/has.jpg';
                                                  break;
                                                case 'Afusic':
                                                  imagePath =
                                                      'assets/images/af.jpg';
                                                  break;
                                                case 'Annural Khalid':
                                                  imagePath =
                                                      'assets/images/jhol.jpg';
                                                  break;
                                                   case 'Murtaza Qizilbash':
                                                  imagePath =
                                                      'assets/images/murtaza.jpg';
                                                  break;
                                                case 'Uzair Jaswal':
                                                  imagePath =
                                                      'assets/images/uzair.jpg';
                                                  break;
                                                case 'All Songs':
                                                  imagePath =
                                                      'assets/images/shae.jpg';
                                                  break;
                                                case 'AMVs':
                                                  imagePath =
                                                      'assets/images/Gurenge.jpg';
                                                  break;
                                                default:
                                                  imagePath =
                                                      'assets/images/0016.jpg';
                                              }
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    currentSongs =
                                                        playlist.songs;
                                                    showingPlaylists = false;
                                                    _currentSongIndex = 0;
                                                  });
                                                },
                                                child: Container(
                                                  width: 120,
                                                  margin: EdgeInsets.symmetric(
                                                      horizontal: 8),
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        width: 110,
                                                        height: 110,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          image:
                                                              DecorationImage(
                                                            image: AssetImage(
                                                                imagePath),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      SizedBox(
                                                        height: 14,
                                                        child: Text(
                                                          playlist.name,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            "Recently Played",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Container(
                                          height: 130,
                                          child: recentlyPlayed.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    "No recently played songs",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      recentlyPlayed.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final song =
                                                        recentlyPlayed[index];
                                                    return GestureDetector(
                                                      onTap: () async {
                                                        setState(() {
                                                          currentSongs = [song];
                                                          showingPlaylists =
                                                              false;
                                                          _currentSongIndex = 0;
                                                        });
                                                        try {
                                                          await audioService.playSong(
                                                              0,
                                                              currentSongs,
                                                              _setCurrentSongIndex,
                                                              _setIsPlaying,
                                                              _rotationController);
                                                        } catch (e) {
                                                          // Silent error handling
                                                        }
                                                      },
                                                      child: Container(
                                                        width: 120,
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 8),
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              width: 110,
                                                              height: 110,
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                image:
                                                                    DecorationImage(
                                                                  image: AssetImage(
                                                                      song.image),
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(height: 4),
                                                            SizedBox(
                                                              height: 14,
                                                              child: Text(
                                                                song.title,
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        SizedBox(height: 20),
                                      ],
                                    )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (currentSong != null)
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = min(
                                              constraints.maxWidth * 0.8,
                                              250.0);
                                          return GestureDetector(
                                            onPanDown: (details) => _onSeekTap(
                                                details.localPosition,
                                                Size(size, size)),
                                            onPanUpdate: (details) =>
                                                _onSeekTap(
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
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: _songDuration
                                                                  .inSeconds >
                                                              0
                                                          ? _currentPosition
                                                                  .inSeconds /
                                                              _songDuration
                                                                  .inSeconds
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
                                                    duration: Duration(
                                                        milliseconds: 700),
                                                    child: RotationTransition(
                                                      key: ValueKey(
                                                          currentSong.image),
                                                      turns:
                                                          _rotationController,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            onPressed: _isPlaying
                                                ? _pauseSong
                                                : _resumeSong,
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
                                                _currentPosition =
                                                    Duration.zero;
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
                                      return SizedBox.shrink();
                                    },
                                    childCount: 0,
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
                if (currentSongs.isNotEmpty && showingPlaylists)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showingPlaylists = false;
                        });
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 16),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(currentSong!.image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentSong.artist,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white),
                              onPressed: _isPlaying ? _pauseSong : _resumeSong,
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_next, color: Colors.white),
                              onPressed: _nextSong,
                            ),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
