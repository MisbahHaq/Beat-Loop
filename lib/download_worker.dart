import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'models.dart';

const downloadTaskKey = 'downloadSong';

@pragma('vm:entry-point')
void callbackDispatcher() {
  print("Download worker callbackDispatcher started");
  Workmanager().executeTask((task, inputData) async {
    print("Executing task: $task");
    switch (task) {
      case downloadTaskKey:
        final songTitle = inputData!['songTitle'] as String;
        final songPath = inputData['songPath'] as String;
        final songImage = inputData['songImage'] as String;
        final songArtist = inputData['songArtist'] as String;

        final song = Song(
          title: songTitle,
          path: songPath,
          image: songImage,
          artist: songArtist,
        );

        await downloadSongInBackground(song);
        break;
      case Workmanager.iOSBackgroundTask:
        // Handle iOS background task
        break;
    }

    return Future.value(true);
  });
}

Future<void> downloadSongInBackground(Song song) async {
  print("Starting download for song: ${song.title}");
  try {
    final dir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = song.title.replaceAll(RegExp(r'[^\w\s]+'), '');
    final extension = song.path.split('.').last.split('?').first;
    final uniquePart = song.path.hashCode.toString();
    final fileName = '${sanitizedTitle}_$uniquePart.$extension';
    final file = File('${dir.path}/$fileName');

    if (file.existsSync()) {
      final existingSize = file.lengthSync();
      print(
          "Song already downloaded: ${song.title}, size: $existingSize bytes");
      // Already downloaded
      return;
    }

    print("Downloading song: ${song.title} from ${song.path}");
    const int maxRetries = 3;
    bool success = false;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("Download attempt $attempt/$maxRetries for ${song.title}");
        final response = await Dio().download(song.path, file.path);
        print("Download response status: ${response.statusCode}");
        if (response.statusCode == 200) {
          final fileSize = file.lengthSync();
          print(
              "Download completed for song: ${song.title}, file size: $fileSize bytes");
          // Check minimum size
          const int minFileSize = 1048576; // 1MB
          if (fileSize >= minFileSize) {
            success = true;
            // Update shared preferences or notify
            final prefs = await SharedPreferences.getInstance();
            final downloadedSongs =
                prefs.getStringList('downloadedSongs') ?? [];
            if (!downloadedSongs.contains(song.title)) {
              downloadedSongs.add(song.title);
              await prefs.setStringList('downloadedSongs', downloadedSongs);
            }
            break;
          } else {
            print("Downloaded file too small, retrying");
            await file.delete();
          }
        } else {
          throw Exception("Download failed with status ${response.statusCode}");
        }
      } catch (e) {
        print("Download error on attempt $attempt: $e");
        if (attempt == maxRetries) {
          print("All download attempts failed for ${song.title}");
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    if (!success) {
      // Clean up partial file
      if (file.existsSync()) {
        await file.delete();
      }
    }
  } catch (e) {
    print("Error downloading song: ${song.title}, error: $e");
    // Silent error handling
  }
}
