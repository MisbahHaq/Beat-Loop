import 'dart:io';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const videoUrl = 'https://www.youtube.com/watch?v=-A_r9MKHPLw';

const chromeUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';

Future<void> main() async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 90),
    validateStatus: (_) => true,
  ));

  Future<void> download(String label, Uri url) async {
    final sw = Stopwatch()..start();
    var first = -1;
    try {
      final resp = await dio.get<List<int>>(
        url.toString(),
        options: Options(headers: {'Range': 'bytes=0-', 'user-agent': chromeUa}),
        onReceiveProgress: (got, total) {
          if (first < 0) {
            first = sw.elapsedMilliseconds;
            print('  [$label] FIRST BYTE: ${got}B @${first}ms');
          }
        },
      );
      print('  [$label] status=${resp.statusCode} bytes=${resp.data?.length ?? 0} '
          '@${sw.elapsedMilliseconds}ms firstByte=${first}ms');
    } catch (e) {
      print('  [$label] ERROR @${sw.elapsedMilliseconds}ms firstByte=${first}ms: '
          '${e.runtimeType}');
    }
    print('');
  }

  for (final entry in [
    ('androidSdkless', null),
    ('ios', YoutubeApiClient.ios),
    ('tv', YoutubeApiClient.tv),
    ('androidVr', YoutubeApiClient.androidVr),
  ]) {
    final (name, client) = entry;
    print('== client: $name ==');
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streams
          .getManifest(videoUrl,
              ytClients: client == null ? null : [client],
              requireWatchPage: false)
          .timeout(const Duration(seconds: 45));
      final audio = manifest.audioOnly.toList();
      if (audio.isEmpty) {
        print('  no audio streams');
        continue;
      }
      for (final s in audio) {
        print('  tag=${s.tag} ${s.container.name} ${s.size.totalBytes}B '
            'throttled=${s.isThrottled} c=${s.url.queryParameters['c']} '
            'host=${s.url.host}');
      }
      final mp4 = audio.where((s) => s.container.name == 'mp4');
      final info = mp4.isNotEmpty
          ? mp4.withHighestBitrate()
          : audio.withHighestBitrate();
      await download(name, info.url);
    } catch (e) {
      print('  manifest FAILED: ${e.runtimeType}: $e');
      print('');
    } finally {
      yt.close();
    }
  }

  exit(0);
}
