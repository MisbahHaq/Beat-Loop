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
      print("Song already downloaded: ${song.title}");
      // Already downloaded
      return;
    }

    print("Downloading song: ${song.title} from ${song.path}");
    final response = await Dio().download(song.path, file.path);

    if (response.statusCode == 200) {
      print("Download completed for song: ${song.title}");
      // Update shared preferences or notify
      final prefs = await SharedPreferences.getInstance();
      final downloadedSongs = prefs.getStringList('downloadedSongs') ?? [];
      if (!downloadedSongs.contains(song.title)) {
        downloadedSongs.add(song.title);
        await prefs.setStringList('downloadedSongs', downloadedSongs);
      }
    } else {
      print(
          "Download failed for song: ${song.title}, status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error downloading song: ${song.title}, error: $e");
    // Silent error handling
  }
}
