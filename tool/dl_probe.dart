import 'dart:io';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const videoUrl = 'https://www.youtube.com/watch?v=-A_r9MKHPLw';

const chromeUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';
const androidUa = 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip';

Future<void> main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streams
      .getManifest(videoUrl, requireWatchPage: false)
      .timeout(const Duration(seconds: 45));
  final audio = manifest.audioOnly;
  print('audio streams:');
  for (final s in audio) {
    print('  tag=${s.tag} ${s.container.name} size=${s.size.totalBytes} '
        'throttled=${s.isThrottled} c=${s.url.queryParameters['c']} '
        'params=${s.url.queryParameters.keys.join(',')}');
  }
  final mp4 = audio.where((s) => s.container.name == 'mp4');
  final info =
      mp4.isNotEmpty ? mp4.withHighestBitrate() : audio.withHighestBitrate();
  print('\nchosen tag=${info.tag} url=$info');
  print('full url=${info.url}\n');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    validateStatus: (_) => true,
  ));

  Future<void> attempt(String label, Map<String, String>? headers,
      {Uri? url, bool queryRange = false}) async {
    var u = url ?? info.url;
    if (queryRange) {
      u = u.replace(queryParameters: {...u.queryParameters, 'range': '0-'});
    }
    final sw = Stopwatch()..start();
    try {
      final resp = await dio.get<List<int>>(
        u.toString(),
        options: headers == null ? Options() : Options(headers: headers),
        onReceiveProgress: (got, total) {},
      );
      final data = resp.data;
      print('$label -> status=${resp.statusCode} bytes=${data?.length ?? 0} '
          '@${sw.elapsedMilliseconds}ms');
    } catch (e) {
      print('$label -> ERROR @${sw.elapsedMilliseconds}ms: $e');
    }
    print('');
  }

  await attempt('1. bare GET, no headers', null);
  await attempt('2. Range header only', {'Range': 'bytes=0-'});
  await attempt('3. ChromeUA + Range header',
      {'Range': 'bytes=0-', 'user-agent': chromeUa, 'cookie': 'CONSENT=YES+cb'});
  await attempt('4. ChromeUA + query range', {'user-agent': chromeUa},
      queryRange: true);
  await attempt('5. AndroidUA + Range header',
      {'Range': 'bytes=0-', 'user-agent': androidUa});
  await attempt('6. ChromeUA + Range + Referer', {
    'Range': 'bytes=0-',
    'user-agent': chromeUa,
    'referer': 'https://www.youtube.com/',
    'origin': 'https://www.youtube.com',
  });
  await attempt('7. ChromeUA, no Range at all', {'user-agent': chromeUa});

  print('== HEAD via raw HttpClient ==');
  try {
    final req = await HttpClient()
        .headUrl(info.url)
      ..headers.set('user-agent', chromeUa);
    final resp = await req.close();
    print('HEAD -> ${resp.statusCode} (content-length: '
        '${resp.headers.contentLength})');
    await resp.drain();
  } catch (e) {
    print('HEAD -> ERROR: $e');
  }

  yt.close();
  exit(0);
}
