import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  print('== manifest requireWatchPage: TRUE ==');
  var yt = YoutubeExplode();
  try {
    final sw = Stopwatch()..start();
    final m = await yt.videos.streams
        .getManifest('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
        .timeout(const Duration(seconds: 40));
    print('OK ${m.audioOnly.length} audio streams @${sw.elapsedMilliseconds}ms');
  } catch (e) {
    print('FAILED: ${e.runtimeType}: $e');
  }
  yt.close();

  await Future<void>.delayed(const Duration(seconds: 2));

  print('\n== manifest requireWatchPage: FALSE ==');
  yt = YoutubeExplode();
  try {
    final sw = Stopwatch()..start();
    final m = await yt.videos.streams
        .getManifest('https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            requireWatchPage: false)
        .timeout(const Duration(seconds: 40));
    print('OK ${m.audioOnly.length} audio streams @${sw.elapsedMilliseconds}ms');
  } catch (e) {
    print('FAILED: ${e.runtimeType}: $e');
  }
  yt.close();

  await Future<void>.delayed(const Duration(seconds: 2));

  print('\n== search "never gonna give you up" ==');
  yt = YoutubeExplode();
  try {
    final sw = Stopwatch()..start();
    final r = await yt.search
        .search('never gonna give you up')
        .timeout(const Duration(seconds: 40));
    print('OK ${r.length} results @${sw.elapsedMilliseconds}ms');
    if (r.isNotEmpty) print('  first: ${r.first.title}');
  } catch (e) {
    print('FAILED: ${e.runtimeType}: $e');
  }
  yt.close();

  print('\n== videos.get (metadata) ==');
  yt = YoutubeExplode();
  try {
    final sw = Stopwatch()..start();
    final v = await yt.videos
        .get('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
        .timeout(const Duration(seconds: 40));
    print('OK "${v.title}" @${sw.elapsedMilliseconds}ms');
  } catch (e) {
    print('FAILED: ${e.runtimeType}: $e');
  }
  yt.close();
  exit(0);
}
