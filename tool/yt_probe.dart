import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const videoUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

Future<void> main() async {
  final yt = YoutubeExplode();

  print('== step 1: manifest (requireWatchPage: false) ==');
  Object? manifestError;
  var manifestOk = false;
  try {
    final manifest = await yt.videos.streams
        .getManifest(videoUrl, requireWatchPage: false)
        .timeout(const Duration(seconds: 30));
    manifestOk = true;
    final audio = manifest.audioOnly;
    print('audio streams: ${audio.length}');
    for (final s in audio) {
      print('  tag=${s.tag} ${s.container.name} bitrate=${s.bitrate} '
          'size=${s.size.totalBytes} throttled=${s.isThrottled}');
    }
    final mp4 = audio.where((s) => s.container.name == 'mp4');
    final info =
        mp4.isNotEmpty ? mp4.withHighestBitrate() : audio.withHighestBitrate();
    print('chosen tag=${info.tag} size=${info.size.totalBytes} throttled=${info.isThrottled}');
    print('url=${info.url.toString().substring(0, 180)}...');

    print('== step 2: library stream with 20s stall watchdog ==');
    final chunks = <int>[];
    var firstMs = -1;
    final sw = Stopwatch()..start();
    var done = false;
    final sub = yt.videos.streams.get(info).listen((c) {
      if (firstMs < 0) print('FIRST CHUNK after ${sw.elapsedMilliseconds}ms: ${c.length}B');
      chunks.addAll(c);
      print('  ${chunks.length}/${info.size.totalBytes} @${sw.elapsedMilliseconds}ms');
    }, onError: (e) {
      print('STREAM ERROR: $e');
      done = true;
    }, onDone: () {
      print('STREAM DONE: ${chunks.length}B in ${sw.elapsedMilliseconds}ms');
      done = true;
    });
    final t = Timer(const Duration(seconds: 20), () {
      if (!done) {
        print('!! STALL: 0 chunks in 20s (firstChunkMs=$firstMs)');
        sub.cancel();
        done = true;
      }
    });
    await sub.asFuture().catchError((_) {});
    t.cancel();

    print('== step 3: direct dio GET of same URL ==');
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    final sw2 = Stopwatch()..start();
    var last = 0;
    try {
      final resp = await dio.get<List<int>>(
        info.url.toString(),
        options: Options(responseType: ResponseType.bytes, headers: {
          'Range': 'bytes=0-',
        }),
        onReceiveProgress: (got, total) {
          if (got - last >= 256 * 1024) {
            last = got;
            print('  dio ${got}B @${sw2.elapsedMilliseconds}ms');
          }
        },
      );
      print('DIO DONE: ${resp.data?.length ?? 0}B in ${sw2.elapsedMilliseconds}ms '
          'status=${resp.statusCode}');
    } catch (e) {
      print('DIO ERROR @${sw2.elapsedMilliseconds}ms: ${e.runtimeType}: $e');
    }
  } catch (e) {
    manifestError = e;
    print('MANIFEST ERROR: ${e.runtimeType}: $e');
  }

  if (!manifestOk) {
    print('== retry manifest WITH watch page ==');
    try {
      final m2 = await yt.videos.streams
          .getManifest(videoUrl)
          .timeout(const Duration(seconds: 45));
      print('retry OK: ${m2.audioOnly.length} audio streams');
    } catch (e) {
      print('retry FAILED: ${e.runtimeType}: $e');
    }
  }

  yt.close();
  exit(0);
}
