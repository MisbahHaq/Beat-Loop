import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const chromeUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';

Future<void> main() async {
  final yt = YoutubeExplode();
  final sw = Stopwatch()..start();
  final manifest = await yt.videos.streams
      .getManifest('https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          requireWatchPage: false)
      .timeout(const Duration(seconds: 30));
  print('manifest @${sw.elapsedMilliseconds}ms');
  final audio = manifest.audioOnly;
  final mp4 = audio.where((s) => s.container.name == 'mp4');
  final info =
      mp4.isNotEmpty ? mp4.withHighestBitrate() : audio.withHighestBitrate();
  print('picked tag=${info.tag} ${info.size.totalBytes}B c=${info.url.queryParameters['c']}');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (_) => true,
    headers: {'user-agent': chromeUa, 'cookie': 'CONSENT=YES+cb'},
  ));

  print('\n== direct GET (Range header, library-style) ==');
  final t1 = Stopwatch()..start();
  var first = -1;
  try {
    final resp = await dio.get<List<int>>(
      info.url.toString(),
      options: Options(headers: {'Range': 'bytes=0-'}),
      onReceiveProgress: (got, total) {
        if (first < 0) first = t1.elapsedMilliseconds;
      },
    );
    print('status=${resp.statusCode} bytes=${resp.data?.length ?? 0} '
        'firstByte=${first}ms total=${t1.elapsedMilliseconds}ms');
    if (resp.statusCode == 403) {
      final body = resp.data;
      print('403 body: ${body == null || body.isEmpty ? '(empty)' : String.fromCharCodes(body.take(200))}');
    }
  } catch (e) {
    print('ERROR firstByte=${first}ms @${t1.elapsedMilliseconds}ms: $e');
  }

  print('\n== library stream ==');
  final t2 = Stopwatch()..start();
  final chunks = <int>[];
  var first2 = -1;
  var failed = '';
  final sub = yt.videos.streams.get(info).listen((c) {
    if (first2 < 0) first2 = t2.elapsedMilliseconds;
    chunks.addAll(c);
  }, onError: (Object e) {
    failed = e.toString();
  }, onDone: () {});
  final timer = Timer(const Duration(seconds: 25), () => sub.cancel());
  await sub.asFuture().catchError((_) {});
  timer.cancel();
  print('firstByte=${first2}ms got=${chunks.length}/${info.size.totalBytes}B '
      '@${t2.elapsedMilliseconds}ms ${failed.isNotEmpty ? 'error=$failed' : ''}');

  yt.close();
  exit(0);
}
