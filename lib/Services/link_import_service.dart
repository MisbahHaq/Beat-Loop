import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class ResolvedLink {
  final String sourceUrl;
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final bool needsSearch;

  const ResolvedLink({
    required this.sourceUrl,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    this.needsSearch = false,
  });
}

class LinkImportService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static bool isSpotifyLink(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('open.spotify.com') || host == 'spotify.link';
  }

  static bool isYouTubeLink(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('music.youtube.com');
  }

  Future<ResolvedLink> resolve(String rawUrl) async {
    var url = rawUrl.trim();
    if (url.isEmpty) throw Exception('Paste a link first');
    if (!url.startsWith('http')) url = 'https://$url';
    if (!isSpotifyLink(url) && !isYouTubeLink(url)) {
      throw Exception('Only YouTube and Spotify song links are supported');
    }
    if (isSpotifyLink(url)) return _resolveSpotify(url);
    return _resolveYouTube(url);
  }

  Future<ResolvedLink> _resolveSpotify(String url) async {
    if (url.contains('/track/')) {
      // Spotify audio itself is never downloadable — resolve metadata here,
      // then pick a matching YouTube track in the next step.
    } else if (url.contains('/album/') ||
        url.contains('/playlist/') ||
        url.contains('/artist/') ||
        url.contains('/episode/') ||
        url.contains('/show/')) {
      throw Exception('Only Spotify song links are supported (not albums or playlists)');
    }
    try {
      final response = await _dio.get(
        'https://open.spotify.com/oembed?url=${Uri.encodeComponent(url)}',
      );
      final data = response.data as Map<String, dynamic>;
      final title = (data['title'] as String?)?.trim() ?? '';
      final artist = (data['author_name'] as String?)?.trim() ?? '';
      final thumb = data['thumbnail_url'] as String?;
      if (title.isEmpty) throw Exception('empty');
      return ResolvedLink(
        sourceUrl: url,
        title: title,
        artist: artist.isEmpty ? 'Unknown artist' : artist,
        thumbnailUrl: thumb,
        needsSearch: true,
      );
    } catch (e) {
      throw Exception("Couldn't read that Spotify link");
    }
  }

  Future<ResolvedLink> _resolveYouTube(String url) async {
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos
          .get(url)
          .timeout(const Duration(seconds: 30));
      return ResolvedLink(
        sourceUrl: url,
        title: video.title,
        artist: video.author,
        thumbnailUrl: video.thumbnails.maxResUrl,
        needsSearch: false,
      );
    } on VideoUnavailableException {
      throw Exception('That YouTube video is unavailable');
    } catch (e) {
      throw Exception("Couldn't read that YouTube link");
    } finally {
      yt.close();
    }
  }

  Future<List<Video>> search(String query, {int limit = 5}) async {
    final yt = YoutubeExplode();
    try {
      final results = await yt.search
          .search(query)
          .timeout(const Duration(seconds: 30));
      return results.take(limit).toList();
    } finally {
      yt.close();
    }
  }

  Future<Uint8List> downloadAudio({
    required String videoIdOrUrl,
    void Function(double progress)? onProgress,
    void Function(String phase)? onPhase,
  }) async {
    final yt = YoutubeExplode();
    try {
      final started = DateTime.now();
      debugPrint('[import] phase: fetching stream info for $videoIdOrUrl');
      onPhase?.call('Fetching stream info…');
      Object? firstError;
      StreamManifest? manifest;
      for (final requireWatchPage in [false, true]) {
        try {
          manifest = await yt.videos.streams
              .getManifest(videoIdOrUrl, requireWatchPage: requireWatchPage)
              .timeout(const Duration(seconds: 30));
          debugPrint(
              '[import] manifest OK (requireWatchPage=$requireWatchPage) in ${DateTime.now().difference(started).inMilliseconds}ms');
          break;
        } catch (e) {
          firstError ??= e;
          debugPrint(
              '[import] manifest FAILED (requireWatchPage=$requireWatchPage): ${e.runtimeType}: $e');
        }
      }
      if (manifest == null) {
        throw firstError ?? Exception("Couldn't read this video's streams");
      }

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        debugPrint('[import] no audio streams in manifest');
        throw Exception('No audio stream available for this video');
      }
      final mp4 = audioStreams.where((s) => s.container.name == 'mp4');
      final info = mp4.isNotEmpty
          ? mp4.withHighestBitrate()
          : audioStreams.withHighestBitrate();
      final total = info.size.totalBytes;
      debugPrint(
          '[import] picked stream: ${info.container.name} ${info.bitrate.kiloBitsPerSecond}kbps size=$total url=${info.url.host}');

      onPhase?.call('Downloading audio…');
      onProgress?.call(0);

      Uint8List bytes;
      try {
        debugPrint('[import] trying DIRECT dio download…');
        final t = DateTime.now();
        bytes = await _downloadDirect(info.url, total, onProgress);
        debugPrint(
            '[import] DIRECT OK: ${bytes.length} bytes in ${DateTime.now().difference(t).inMilliseconds}ms');
      } catch (e, st) {
        debugPrint(
            '[import] DIRECT FAILED: ${e.runtimeType}: $e — falling back to library stream');
        debugPrint('$st');
        debugPrint('[import] trying LIBRARY stream…');
        final t = DateTime.now();
        bytes = await _downloadViaLibrary(yt, info, total, onProgress);
        debugPrint(
            '[import] LIBRARY OK: ${bytes.length} bytes in ${DateTime.now().difference(t).inMilliseconds}ms');
      }

      if (total > 0 && (bytes.length - total).abs() > total * 0.02) {
        throw Exception(
            'Download was incomplete (${bytes.length} of $total bytes) — try again');
      }
      onProgress?.call(1);
      debugPrint(
          '[import] download COMPLETE: ${bytes.length} bytes, total ${DateTime.now().difference(started).inMilliseconds}ms');
      return bytes;
    } finally {
      yt.close();
    }
  }

  /// Direct HTTP download of the stream URL: real progress callbacks and a
  /// receive timeout that acts as a stall detector.
  Future<Uint8List> _downloadDirect(
    Uri url,
    int expected,
    void Function(double progress)? onProgress,
  ) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));
    var lastLoggedPct = -10;
    final t = DateTime.now();
    final response = await dio.get<List<int>>(
      url.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Range': 'bytes=0-'},
      ),
      onReceiveProgress: (got, total) {
        final effective = total > 0 ? total : expected;
        if (effective > 0) {
          onProgress?.call((got / effective).clamp(0.0, 1.0));
          final pct = (got / effective * 100).floor();
          if (pct >= lastLoggedPct + 10) {
            lastLoggedPct = pct - (pct % 10);
            debugPrint(
                '[import] direct: $pct% ($got/$effective) ${DateTime.now().difference(t).inMilliseconds}ms');
          }
        }
      },
    );
    final data = response.data;
    debugPrint(
        '[import] direct response: status=${response.statusCode} bytes=${data?.length ?? 0}');
    if (data == null || data.isEmpty) {
      throw Exception('Empty response from YouTube');
    }
    return Uint8List.fromList(data);
  }

  /// Fallback: youtube_explode's stream, guarded by a 15s stall watchdog.
  Future<Uint8List> _downloadViaLibrary(
    YoutubeExplode yt,
    AudioStreamInfo info,
    int expected,
    void Function(double progress)? onProgress,
  ) async {
    final completer = Completer<Uint8List>();
    final chunks = <int>[];
    Timer? watchdog;
    var chunkCount = 0;
    var lastLoggedPct = -10;
    final t = DateTime.now();

    void arm() {
      watchdog?.cancel();
      watchdog = Timer(const Duration(seconds: 15), () {
        debugPrint(
            '[import] library stream STALLED: $chunkCount chunks, ${chunks.length} bytes after ${DateTime.now().difference(t).inMilliseconds}ms — aborting');
        if (!completer.isCompleted) {
          completer.completeError(Exception(
              'Download stalled — check your connection and try again'));
        }
      });
    }

    arm();
    final sub = yt.videos.streams.get(info).listen(
      (chunk) {
        if (chunkCount == 0) {
          debugPrint(
              '[import] library: first chunk after ${DateTime.now().difference(t).inMilliseconds}ms (${chunk.length} bytes)');
        }
        arm();
        chunkCount++;
        chunks.addAll(chunk);
        if (expected > 0) {
          onProgress?.call((chunks.length / expected).clamp(0.0, 1.0));
          final pct = (chunks.length / expected * 100).floor();
          if (pct >= lastLoggedPct + 25) {
            lastLoggedPct = pct - (pct % 25);
            debugPrint(
                '[import] library: $pct% ($chunkCount chunks) ${DateTime.now().difference(t).inMilliseconds}ms');
          }
        }
      },
      onError: (Object e) {
        debugPrint(
            '[import] library stream ERROR: ${e.runtimeType}: $e after ${DateTime.now().difference(t).inMilliseconds}ms');
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        debugPrint(
            '[import] library stream DONE: $chunkCount chunks, ${chunks.length} bytes in ${DateTime.now().difference(t).inMilliseconds}ms');
        if (!completer.isCompleted) {
          completer.complete(Uint8List.fromList(chunks));
        }
      },
    );

    try {
      final bytes = await completer.future;
      if (bytes.isEmpty) {
        throw Exception('Download produced an empty file — try again');
      }
      return bytes;
    } finally {
      watchdog?.cancel();
      await sub.cancel();
    }
  }

  Future<Uint8List> fetchBytes(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) throw Exception('Empty response');
    return Uint8List.fromList(data);
  }

  String audioFileName(String title) {
    final slug = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final safe = slug.isEmpty ? 'song' : slug;
    return '${safe}_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }
}
