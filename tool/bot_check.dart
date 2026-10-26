import 'dart:convert';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  print('== watch page check ==');
  try {
    final req = await HttpClient().getUrl(Uri.parse(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
    req.headers.set('user-agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36');
    req.headers.set('cookie', 'CONSENT=YES+cb');
    final resp = await req.close().timeout(const Duration(seconds: 20));
    final bytes = await resp.fold<List<int>>([], (a, b) => a..addAll(b))
        .timeout(const Duration(seconds: 20));
    final body = utf8.decode(bytes, allowMalformed: true);
    print('status=${resp.statusCode} len=${body.length}');
    print('bot-check: ${body.contains("confirm you") || body.contains('use Google Search to check if you') || body.contains('consent.youtube.com') || body.contains('before you continue')}');
    print('playable: ${body.contains('"playabilityStatus"')}');
  } catch (e) {
    print('watch page ERROR: $e');
  }

  print('\n== fresh manifest + download (dQw) ==');
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streams
        .getManifest('https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            requireWatchPage: false)
        .timeout(const Duration(seconds: 45));
    final audio = manifest.audioOnly;
    final mp4 = audio.where((s) => s.container.name == 'mp4');
    final info =
        mp4.isNotEmpty ? mp4.withHighestBitrate() : audio.withHighestBitrate();
    print('picked tag=${info.tag} ${info.size.totalBytes}B');
    final sw = Stopwatch()..start();
    final chunks = <int>[];
    var firstMs = -1;
    final sub = yt.videos.streams.get(info).listen((c) {
      if (firstMs < 0) firstMs = sw.elapsedMilliseconds;
      chunks.addAll(c);
      if (sw.elapsedMilliseconds % 3000 < 100) {
        print('  ${chunks.length}/${info.size.totalBytes} @${sw.elapsedMilliseconds}ms');
      }
    }, onError: (Object e) {
      print('STREAM ERROR @${sw.elapsedMilliseconds}ms: $e');
    }, onDone: () {
      print('DONE ${chunks.length}B in ${sw.elapsedMilliseconds}ms firstByte=${firstMs}ms');
    });
    await sub.asFuture().catchError((_) {});
    if (firstMs < 0 && chunks.isEmpty) {
      print('NO CHUNKS after ${sw.elapsedMilliseconds}ms');
    }
  } catch (e) {
    print('ERROR: $e');
  } finally {
    yt.close();
    exit(0);
  }
}
