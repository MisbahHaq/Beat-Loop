import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models.dart';

class BeatLoopAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AudioPlayer? _player;
  List<Song> _songs = [];
  int _currentIndex = 0;
  Function(int)? _onPlaySong;
  bool _listening = false;

  void attachPlayer(AudioPlayer player) {
    if (_listening) return;
    _player = player;
    _listening = true;

    _player!.onPlayerComplete.listen((_) {
      skipToNext();
    });
    _player!.onPositionChanged.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
    _player!.onDurationChanged.listen((duration) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.ready,
      ));
    });
  }

  void setCallbacks({
    required List<Song> songs,
    required int index,
    required Function(int) onPlaySong,
  }) {
    _songs = songs;
    _currentIndex = index;
    _onPlaySong = onPlaySong;
    queue.add(songs.map((s) => _mediaItemFromSong(s)).toList());
  }

  MediaItem _mediaItemFromSong(Song song) {
    return MediaItem(
      id: song.path,
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse('asset:///assets/images/${song.image.replaceFirst('assets/images/', '')}'),
    );
  }

  void updateMetadata(Song song) {
    mediaItem.add(_mediaItemFromSong(song));
  }

  void notifyPlay() {
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
    ));
  }

  void notifyPause() {
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
    ));
  }

  void notifyStopped() {
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
      controls: [],
    ));
  }

  @override
  Future<void> play() async {
    _player?.resume();
    notifyPlay();
  }

  @override
  Future<void> pause() async {
    _player?.pause();
    notifyPause();
  }

  @override
  Future<void> stop() async {
    _player?.stop();
    notifyStopped();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_songs.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _songs.length;
    _currentIndex = nextIndex;
    _onPlaySong?.call(nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_songs.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
    _currentIndex = prevIndex;
    _onPlaySong?.call(prevIndex);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  void updateIndex(int index) {
    _currentIndex = index;
  }
}
