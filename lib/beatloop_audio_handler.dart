import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class BeatLoopAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AudioPlayer? _player;
  List<Song> _songs = [];
  int _currentIndex = 0;
  Function(int)? _onPlaySong;
  bool _listening = false;
  final Map<String, String> _artFileCache = {};

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
      _withDuration(duration);
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
  }

  MediaItem _mediaItemFromSong(Song song, {Duration? duration, Uri? artUri}) {
    return MediaItem(
      id: song.path,
      title: song.title,
      artist: song.artist,
      album: 'Beat Loop',
      duration: duration,
      artUri: artUri ?? _assetArtUri(song.image),
    );
  }

  Uri _assetArtUri(String imagePath) => Uri.parse(
      'asset:///assets/images/${imagePath.replaceFirst('assets/images/', '')}');

  Future<Uri> _resolveArtUri(String imagePath) async {
    try {
      var filePath = _artFileCache[imagePath];
      if (filePath == null) {
        final dir = await getApplicationDocumentsDirectory();
        final artDir = await Directory('${dir.path}/art').create(recursive: true);
        final fileName = imagePath.split('/').last;
        final file = File('${artDir.path}/$fileName');
        if (!file.existsSync()) {
          final data = await rootBundle.load(imagePath);
          await file.writeAsBytes(data.buffer.asUint8List());
        }
        filePath = file.path;
        _artFileCache[imagePath] = filePath;
      }
      return Uri.file(filePath);
    } catch (e) {
      return _assetArtUri(imagePath);
    }
  }

  Future<void> updateMetadata(Song song, {Duration? duration}) async {
    final artUri = await _resolveArtUri(song.image);
    mediaItem.add(_mediaItemFromSong(song, duration: duration, artUri: artUri));
  }

  void _withDuration(Duration duration) {
    final current = mediaItem.value;
    if (current == null || current.duration == duration) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.ready,
      ));
      return;
    }
    mediaItem.add(current.copyWith(duration: duration));
  }

  void notifyPlay() {
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: {MediaAction.play, MediaAction.pause, MediaAction.seek},
      processingState: AudioProcessingState.ready,
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
      systemActions: {MediaAction.play, MediaAction.pause, MediaAction.seek},
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