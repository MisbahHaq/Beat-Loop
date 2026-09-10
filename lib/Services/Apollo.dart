import 'dart:math';
import 'package:flutter/material.dart';
import '../models.dart';
import '../audio_service.dart';
import '../playlist_service.dart';
import '../songs_data.dart';
import '../theme.dart';
import '../widgets/washi_tape.dart';
import '../widgets/sticker_badge.dart';
import '../widgets/neo_brutalist_card.dart';
import '../widgets/halftone_painter.dart';
import '../widgets/smiley_badge.dart';
import '../widgets/star_stamp.dart';

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
  Playlist? selectedPlaylist;
  bool showingPlaylists = true;
  bool isSearching = false;
  String searchQuery = '';
  List<Song> searchResults = [];
  List<Song> recentlyPlayed = [];

  void _setCurrentSongIndex(int index) =>
      setState(() => _currentSongIndex = index);
  void _setIsPlaying(bool playing) => setState(() => _isPlaying = playing);
  void _setIsLooping(bool looping) => setState(() => _isLooping = looping);
  void _playSong(int index) async {
    try {
      await audioService.playSong(index, currentSongs, _setCurrentSongIndex,
          _setIsPlaying, _rotationController);
      final song = currentSongs[index];
      setState(() {
        recentlyPlayed.removeWhere(
            (s) => s.title == song.title && s.artist == song.artist);
        recentlyPlayed.insert(0, song);
        if (recentlyPlayed.length > 10) {
          recentlyPlayed = recentlyPlayed.take(10).toList();
        }
      });
    } catch (e) {}
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
    audioService.toggleShuffle(_isShuffling, _setIsShuffleOn);
  }

  void _setIsShuffleOn(bool v) => setState(() => _isShuffling = v);

  @override
  void initState() {
    super.initState();
    audioService.initializeAudioSession();
    audioService.listenAudioPlayerEvents(() {
      _nextSong();
    }, (duration) {
      setState(() => _currentPosition = duration);
    }, (duration) {
      setState(() => _songDuration = duration);
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

  // ─── HEADER ───
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar with search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!showingPlaylists)
                GestureDetector(
                  onTap: () => setState(() => showingPlaylists = true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.paperWhite,
                      border: Border.all(color: AppTheme.ink, width: 3),
                      boxShadow: [
                        BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Icon(Icons.arrow_back, color: AppTheme.ink, size: 22),
                  ),
                )
              else
                SmileyBadge(size: 44, angle: -8),
              const Spacer(),
              if (showingPlaylists && !isSearching)
                GestureDetector(
                  onTap: () => setState(() => isSearching = true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberYellow,
                      border: Border.all(color: AppTheme.ink, width: 3),
                      boxShadow: [
                        BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Icon(Icons.search, color: AppTheme.ink, size: 22),
                  ),
                ),
              if (isSearching)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isSearching = false;
                      searchQuery = '';
                      searchResults = [];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.hotPink,
                      border: Border.all(color: AppTheme.ink, width: 3),
                      boxShadow: [
                        BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              if (!showingPlaylists && !isSearching)
                GestureDetector(
                  onTap: () => _downloadAllSongsWithProgress(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan,
                      border: Border.all(color: AppTheme.ink, width: 3),
                      boxShadow: [
                        BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Icon(Icons.download, color: AppTheme.ink, size: 22),
                  ),
                ),
            ],
          ),

          if (isSearching) ...[
            const SizedBox(height: 16),
            _buildSearchBar(),
          ],

          if (!isSearching) ...[
            const SizedBox(height: 20),
            // Editorial heading with washi tape
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text("Your Library", style: AppTheme.headingLg),
                Positioned(
                  top: -6,
                  right: 0,
                  child: WashiTape.striped(
                    width: 60,
                    angle: -5,
                    color: AppTheme.softPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "PLAYLISTS",
              style: AppTheme.mono.copyWith(
                letterSpacing: 3,
                color: AppTheme.dimText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperWhite,
        border: Border.all(color: AppTheme.ink, width: 3),
        boxShadow: [
          BoxShadow(color: AppTheme.ink, offset: Offset(3, 3)),
        ],
      ),
      child: TextField(
        autofocus: true,
        style: AppTheme.body.copyWith(color: AppTheme.ink),
        decoration: InputDecoration(
          hintText: 'search songs...',
          hintStyle: AppTheme.hand.copyWith(color: AppTheme.dimText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(Icons.search, color: AppTheme.ink),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
            searchResults = allSongs
                .where((song) =>
                    song.title.toLowerCase().contains(searchQuery))
                .toList();
          });
        },
      ),
    );
  }

  // ─── PLAYLIST CARDS ───
  Widget _buildPlaylistSection() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          final colors = [
            AppTheme.cyberYellow,
            AppTheme.hotPink,
            AppTheme.electricCyan,
            AppTheme.vibrantOrange,
            AppTheme.softLavender,
            AppTheme.softPink,
            AppTheme.mutedGreen,
          ];
          final color = colors[index % colors.length];
          final angles = [-4.0, 3.0, -2.0, 5.0, -3.0, 2.0, -5.0];
          final angle = angles[index % angles.length];

          String imagePath;
          switch (playlist.name) {
            case 'Hasan Raheem':
              imagePath = 'assets/images/has.jpg';
              break;
            case 'Afusic':
              imagePath = 'assets/images/af.jpg';
              break;
            case 'Annural Khalid':
              imagePath = 'assets/images/jhol.jpg';
              break;
            case 'Murtaza Qizilbash':
              imagePath = 'assets/images/murtaza.jpg';
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
              });
            },
            child: Transform.rotate(
              angle: angle * pi / 180,
              child: Container(
                width: 125,
                margin: const EdgeInsets.only(right: 14),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Card
                    NeoBrutalistCard(
                      backgroundColor: color,
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRect(
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            color: AppTheme.paperWhite,
                            child: Text(
                              playlist.name,
                              style: AppTheme.monoAccent.copyWith(fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Washi tape on top
                    Positioned(
                      top: -8,
                      right: -4,
                      child: WashiTape.solid(
                        width: 40,
                        angle: 12,
                        color: AppTheme.washiColors[
                            index % AppTheme.washiColors.length],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── RECENTLY PLAYED ───
  Widget _buildRecentlyPlayed() {
    if (recentlyPlayed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.warmCream,
            border: Border.all(color: AppTheme.ink, width: 2),
            boxShadow: [
              BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
            ],
          ),
          child: Row(
            children: [
              StarStamp.pink(size: 28, angle: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "no songs played yet — start vibing!",
                  style: AppTheme.hand.copyWith(color: AppTheme.dimText),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recentlyPlayed.length,
        itemBuilder: (context, index) {
          final song = recentlyPlayed[index];
          return GestureDetector(
            onTap: () async {
              setState(() {
                currentSongs = [song];
                showingPlaylists = false;
                _currentSongIndex = 0;
              });
              try {
                await audioService.playSong(
                    0, currentSongs, _setCurrentSongIndex,
                    _setIsPlaying, _rotationController);
              } catch (e) {}
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.ink, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                      ],
                      image: DecorationImage(
                        image: AssetImage(song.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.title,
                    style: AppTheme.monoSm.copyWith(fontSize: 8),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── SEARCH RESULTS ───
  Widget _buildSearchResults() {
    if (searchResults.isEmpty && searchQuery.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmileyBadge(size: 56, color: AppTheme.softPink, angle: -10),
              const SizedBox(height: 16),
              Text("Ask Misbah to add it", style: AppTheme.handLg),
              const SizedBox(height: 4),
              Text("¯\\_(ツ)_/¯", style: AppTheme.mono),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = searchResults[index];
          return GestureDetector(
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.paperWhite,
                border: Border.all(color: AppTheme.ink, width: 2),
                boxShadow: [
                  BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.ink, width: 2),
                      image: DecorationImage(
                        image: AssetImage(song.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title, style: AppTheme.bodyBold),
                        Text(song.artist, style: AppTheme.monoSm),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: searchResults.length,
      ),
    );
  }

  // ─── NOW PLAYING ───
  Widget _buildNowPlaying(Song currentSong) {
    return Container(
      color: AppTheme.cream,
      child: Stack(
        children: [
          // Halftone background
          HalftoneBackground(
            dotColor: AppTheme.ink,
            dotSpacing: 24,
            maxDotSize: 3,
            child: const SizedBox.expand(),
          ),
          // Colored accent block behind art
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: AppTheme.cyberYellow.withOpacity(0.3),
                  border: Border.all(color: AppTheme.ink, width: 3),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: 5 * pi / 180,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        color: AppTheme.hotPink.withOpacity(0.2),
                        border: Border.all(color: AppTheme.ink, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => showingPlaylists = true),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.paperWhite,
                          border: Border.all(color: AppTheme.ink, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.ink, offset: Offset(2, 2)),
                          ],
                        ),
                        child: Icon(Icons.arrow_back,
                            color: AppTheme.ink, size: 22),
                      ),
                    ),
                    StarStamp.yellow(size: 32, angle: -12),
                  ],
                ),
                const SizedBox(height: 30),

                // Album art with progress ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress ring
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: _songDuration.inSeconds > 0
                            ? _currentPosition.inSeconds /
                                _songDuration.inSeconds
                            : 0,
                        strokeWidth: 6,
                        backgroundColor: AppTheme.warmCream,
                        valueColor:
                            AlwaysStoppedAnimation(AppTheme.hotPink),
                      ),
                    ),
                    // Album art container
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.ink, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.ink,
                            offset: AppTheme.shadowOffsetLg,
                          ),
                        ],
                      ),
                      child: RotationTransition(
                        turns: _rotationController,
                        child: Image.asset(
                          currentSong.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Washi tape on album
                    Positioned(
                      top: 10,
                      right: 0,
                      child: WashiTape.polkaDot(
                        width: 50,
                        angle: 15,
                        color: AppTheme.softCyan,
                      ),
                    ),
                    // Sticker badge
                    Positioned(
                      bottom: 10,
                      left: 0,
                      child: StickerBadge.yellow(
                        label: "NOW",
                        size: 36,
                        angle: -8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Song title
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      currentSong.title,
                      style: AppTheme.headingMd,
                      textAlign: TextAlign.center,
                    ),
                    Positioned(
                      bottom: -4,
                      left: 0,
                      right: 0,
                      child: WashiTape.solid(
                        width: double.infinity,
                        height: 6,
                        angle: 0,
                        color: AppTheme.cyberYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Artist with annotation style
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.ink, width: 1.5),
                  ),
                  child: Text(
                    currentSong.artist,
                    style: AppTheme.hand.copyWith(
                      color: AppTheme.hotPink,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Time display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: AppTheme.mono.copyWith(color: AppTheme.dimText),
                    ),
                    Text(
                      _formatDuration(_songDuration),
                      style: AppTheme.mono.copyWith(color: AppTheme.dimText),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Playback controls
                _buildPlaybackControls(),
                const SizedBox(height: 24),

                // Decorative elements
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StarStamp.cyan(size: 20, angle: 10),
                    const SizedBox(width: 8),
                    SmileyBadge(size: 24, angle: -6),
                    const SizedBox(width: 8),
                    StarStamp.yellow(size: 20, angle: -15),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.paperWhite,
        border: Border.all(color: AppTheme.ink, width: 3),
        boxShadow: [
          BoxShadow(color: AppTheme.ink, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Loop
          GestureDetector(
            onTap: _toggleLoop,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isLooping ? AppTheme.electricCyan : AppTheme.warmCream,
                border: Border.all(color: AppTheme.ink, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Icon(
                Icons.loop,
                color: AppTheme.ink,
                size: 20,
              ),
            ),
          ),
          // Previous
          GestureDetector(
            onTap: _prevSong,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warmCream,
                border: Border.all(color: AppTheme.ink, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Icon(Icons.skip_previous, color: AppTheme.ink, size: 22),
            ),
          ),
          // Play/Pause
          GestureDetector(
            onTap: _isPlaying ? _pauseSong : _resumeSong,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isPlaying ? AppTheme.hotPink : AppTheme.cyberYellow,
                border: Border.all(color: AppTheme.ink, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.ink, offset: Offset(3, 3)),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: _isPlaying ? Colors.white : AppTheme.ink,
                size: 30,
              ),
            ),
          ),
          // Next
          GestureDetector(
            onTap: _nextSong,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warmCream,
                border: Border.all(color: AppTheme.ink, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Icon(Icons.skip_next, color: AppTheme.ink, size: 22),
            ),
          ),
          // Shuffle
          GestureDetector(
            onTap: _toggleShuffle,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isShuffling ? AppTheme.vibrantOrange : AppTheme.warmCream,
                border: Border.all(color: AppTheme.ink, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Icon(
                Icons.shuffle,
                color: _isShuffling ? Colors.white : AppTheme.ink,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MINI PLAYER ───
  Widget _buildMiniPlayer(Song currentSong) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => setState(() => showingPlaylists = false),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppTheme.paperWhite,
            border: Border.all(color: AppTheme.ink, width: 3),
            boxShadow: [
              BoxShadow(color: AppTheme.ink, offset: Offset(0, -3)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  const SizedBox(width: 14),
                  // Album art
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.ink, width: 2),
                      image: DecorationImage(
                        image: AssetImage(currentSong.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: AppTheme.bodyBold.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist,
                          style: AppTheme.monoSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  GestureDetector(
                    onTap: _isPlaying ? _pauseSong : _resumeSong,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isPlaying
                            ? AppTheme.hotPink
                            : AppTheme.cyberYellow,
                        border: Border.all(color: AppTheme.ink, width: 2),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: _isPlaying ? Colors.white : AppTheme.ink,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _nextSong,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warmCream,
                        border: Border.all(color: AppTheme.ink, width: 2),
                      ),
                      child: Icon(Icons.skip_next,
                          color: AppTheme.ink, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
              // Decorative tape
              Positioned(
                top: -6,
                left: 50,
                child: WashiTape.striped(
                  width: 35,
                  height: 12,
                  angle: 8,
                  color: AppTheme.softCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  // ─── MAIN BUILD ───
  @override
  Widget build(BuildContext context) {
    final Song? currentSong =
        currentSongs.isNotEmpty ? currentSongs[_currentSongIndex] : null;

    return WillPopScope(
      onWillPop: () async {
        if (!showingPlaylists) {
          setState(() => showingPlaylists = true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: showingPlaylists
            ? _buildPlaylistView(currentSong)
            : (currentSong != null
                ? _buildNowPlaying(currentSong)
                : const SizedBox()),
      ),
    );
  }

  Widget _buildPlaylistView(Song? currentSong) {
    return Stack(
      children: [
        // Halftone background
        HalftoneBackground(
          dotColor: AppTheme.ink,
          dotSpacing: 28,
          maxDotSize: 2.5,
          child: const SizedBox.expand(),
        ),
        // Decorative corner stars
        Positioned(
          top: 40,
          right: 80,
          child: StarStamp.yellow(size: 24, angle: 18),
        ),
        Positioned(
          top: 140,
          left: 10,
          child: StarStamp.cyan(size: 18, angle: -10),
        ),

        CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  if (!isSearching) ...[
                    const SizedBox(height: 20),
                    _buildPlaylistSection(),
                  ],
                  if (!isSearching) ...[
                    const SizedBox(height: 28),
                    // Recently played heading
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Text("Recently Played", style: AppTheme.headingSm),
                          Positioned(
                            top: 2,
                            right: -8,
                            child: WashiTape.crossHatch(
                              width: 45,
                              height: 10,
                              angle: -6,
                              color: AppTheme.softYellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "YOUR RECENT VIBES",
                        style: AppTheme.monoSm.copyWith(letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentlyPlayed(),
                    const SizedBox(height: 28),
                    // Decorative divider
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 2,
                            color: AppTheme.ink.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          SmileyBadge(size: 22, angle: 10),
                          const SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 2,
                            color: AppTheme.ink.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            // Search results
            if (isSearching) _buildSearchResults(),
            // Bottom spacing for mini player
            SliverToBoxAdapter(
              child: SizedBox(
                height: currentSongs.isNotEmpty ? 100 : 40,
              ),
            ),
          ],
        ),
        // Mini player
        if (currentSongs.isNotEmpty && showingPlaylists && currentSong != null)
          _buildMiniPlayer(currentSong),
      ],
    );
  }
}
