import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AudioSession _audioSession;

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> initializeAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(AudioSessionConfiguration.music());
  }

  void listenAudioPlayerEvents(
      Function() onPlayerComplete,
      Function(Duration) onPositionChanged,
      Function(Duration) onDurationChanged) {
    _audioPlayer.onPlayerComplete.listen((_) => onPlayerComplete());
    _audioPlayer.onPositionChanged.listen(onPositionChanged);
    _audioPlayer.onDurationChanged.listen(onDurationChanged);
  }

  Future<void> playSong(
      int index,
      List<Song> currentSongs,
      Function(int) setCurrentSongIndex,
      Function(bool) setIsPlaying,
      AnimationController rotationController) async {
    if (currentSongs.isEmpty || index >= currentSongs.length) return;

    await _audioSession.setActive(true);
    await _audioPlayer.stop();

    final song = currentSongs[index];
    final file = await _getLocalFile(song);

    // 🔽 If file doesn't exist, download and show snackbar
    if (!file.existsSync()) {
      // Note: Snackbar needs context, so this will be handled in the widget
      await _downloadFile(song.path, file);
    }

    if (await file.exists()) {
      final fileSize = await file.length();
      print("Playing song: ${song.title}, file size: $fileSize bytes");
      if (fileSize == 0) {
        throw Exception("Audio file is empty");
      }
      // Check for minimum file size (1MB = 1048576 bytes) to detect incomplete downloads
      const int minFileSize = 1048576; // 1MB
      if (fileSize < minFileSize) {
        print("File size too small, re-downloading: ${song.title}");
        await file.delete();
        await _downloadFile(song.path, file);
        final newFileSize = await file.length();
        print("Re-downloaded file size: $newFileSize bytes");
        if (newFileSize < minFileSize) {
          throw Exception("Re-downloaded file is still too small");
        }
      }
    } else {
      throw Exception("Audio file does not exist");
    }

    await _audioPlayer.play(DeviceFileSource(file.path));

    setCurrentSongIndex(index);
    setIsPlaying(true);
    rotationController.repeat();
  }

  Future<void> downloadAllSongsWithProgress(
      BuildContext context, List<Song> allSongs) async {
    // First, count how many need downloading
    int toDownload = 0;
    for (final song in allSongs) {
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
                for (final song in allSongs) {
                  final file = await _getLocalFile(song);
                  if (!file.existsSync()) {
                    try {
                      await _downloadFile(song.path, file);
                      completed++;
                      setDialogState(() {}); // refresh dialog
                    } catch (e) {
                      print("Failed to download ${song.title}: $e");
                      // Continue to next song
                    }
                  }
                }
                Navigator.of(context).pop(); // close dialog
              });
            }

            return AlertDialog(
              title: Text("Downloading Songs"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: completed / toDownload),
                  SizedBox(height: 16),
                  Text("Remaining: ${toDownload - completed}"),
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

  Future<File> getLocalFile(Song song) async {
    return _getLocalFile(song);
  }

  Future<void> _downloadFile(String url, File file) async {
    print("Starting download for URL: $url to file: ${file.path}");
    const int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("Download attempt $attempt/$maxRetries");
        final response = await Dio().download(url, file.path);
        print("Download response status: ${response.statusCode}");
        if (response.statusCode == 200) {
          final fileSize = await file.length();
          print("Downloaded file size: $fileSize bytes");
          if (fileSize == 0) {
            await file.delete();
            throw Exception("Downloaded file is empty");
          }
          return; // Success
        } else {
          throw Exception("Download failed with status ${response.statusCode}");
        }
      } catch (e) {
        print("Download error on attempt $attempt: $e");
        if (await file.exists()) {
          final fileSize = await file.length();
          print("File exists after error, size: $fileSize bytes");
          if (fileSize == 0) {
            await file.delete();
          }
        }
        if (attempt == maxRetries) {
          rethrow;
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  void pauseSong(
      Function(bool) setIsPlaying, AnimationController rotationController) {
    _audioPlayer.pause();
    setIsPlaying(false);
    rotationController.stop();
  }

  void resumeSong(
      Function(bool) setIsPlaying, AnimationController rotationController) {
    _audioPlayer.resume();
    setIsPlaying(true);
    rotationController.repeat();
  }

  void nextSong(bool isShuffling, int currentSongIndex, List<Song> currentSongs,
      Function(int) playSong) {
    if (isShuffling) {
      int newIndex;
      do {
        newIndex = Random().nextInt(currentSongs.length);
      } while (newIndex == currentSongIndex && currentSongs.length > 1);
      playSong(newIndex);
    } else {
      playSong((currentSongIndex + 1) % currentSongs.length);
    }
  }

  void prevSong(bool isShuffling, int currentSongIndex, List<Song> currentSongs,
      Function(int) playSong) {
    if (isShuffling) {
      int newIndex;
      do {
        newIndex = Random().nextInt(currentSongs.length);
      } while (newIndex == currentSongIndex && currentSongs.length > 1);
      playSong(newIndex);
    } else {
      playSong(
          (currentSongIndex - 1 + currentSongs.length) % currentSongs.length);
    }
  }

  void toggleLoop(bool isLooping, Function(bool) setIsLooping) {
    setIsLooping(!isLooping);
    _audioPlayer
        .setReleaseMode(isLooping ? ReleaseMode.loop : ReleaseMode.release);
  }

  void toggleShuffle(bool isShuffling, Function(bool) setIsShuffling) {
    setIsShuffling(!isShuffling);
  }

  void onSeekTap(Offset localPosition, Size size, Duration songDuration,
      Function(Duration) seek) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > size.width / 2) return;

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    final percent = angle / (2 * pi);
    final seconds =
        (songDuration.inSeconds * percent).clamp(0, songDuration.inSeconds);
    seek(Duration(seconds: seconds.toInt()));
  }

  void dispose() {
    _audioPlayer.dispose();
    _audioSession.setActive(false);
  }
}
