import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'log.dart';
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
    if (!isYouTubeLink(url)) {
      throw Exception('Only YouTube song links are supported');
    }
    return _resolveYouTube(url);
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
      // Rank by title-word overlap with the query so the actual song comes
      // first instead of whatever YouTube's fuzzy match returns.
      final wanted = _words(query);
      final ranked = results.toList()
        ..sort((a, b) =>
            _matchScore(b.title, wanted).compareTo(_matchScore(a.title, wanted)));
      return ranked.take(limit).toList();
    } finally {
      yt.close();
    }
  }

  Set<String> _words(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1 && !const {'the', 'a', 'an', 'of', 'by', 'with', 'unknown', 'artist'}.contains(w))
      .toSet();

  int _matchScore(String title, Set<String> wanted) {
    if (wanted.isEmpty) return 0;
    final tw = _words(title);
    var score = tw.where(wanted.contains).length;
    if (tw.containsAll(wanted)) score += 5;
    return score;
  }

  Future<Uint8List> downloadAudio({
    required String videoIdOrUrl,
    void Function(double progress)? onProgress,
    void Function(String phase)? onPhase,
  }) async {
    // YouTube rate-limits aggressive request patterns with 403s / hangs that
    // clear after a minute. Retry the whole fetch+download cycle with backoff
    // before giving up.
    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _downloadAudioOnce(
          videoIdOrUrl: videoIdOrUrl,
          onProgress: onProgress,
          onPhase: onPhase,
          attempt: attempt,
        );
      } catch (e) {
        lastError = e;
        final retryable = _isRateLimitError(e);
        logLine(
            '[import] attempt $attempt/$maxAttempts failed (${retryable ? 'retryable' : 'fatal'}): ${e.runtimeType}: $e');
        if (!retryable || attempt == maxAttempts) rethrow;
        final delay = Duration(seconds: attempt == 1 ? 15 : 60);
        logLine('[import] waiting ${delay.inSeconds}s before retry…');
        onPhase?.call(
            'YouTube is busy — retrying in ${delay.inSeconds}s…');
        await Future<void>.delayed(delay);
      }
    }
    throw lastError ?? Exception('Download failed');
  }

  bool _isRateLimitError(Object e) {
    if (e is RequestLimitExceededException) return true;
    if (e is TimeoutException) return true;
    if (e is FatalFailureException) return true;
    if (e is DioException) {
      final s = e.response?.statusCode;
      if (s == 403 || s == 429 || s == 500 || s == 502 || s == 503) return true;
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
    }
    final msg = e.toString();
    return msg.contains('stalled') || msg.contains('incomplete');
  }

  Future<Uint8List> _downloadAudioOnce({
    required String videoIdOrUrl,
    void Function(double progress)? onProgress,
    void Function(String phase)? onPhase,
    required int attempt,
  }) async {
    final yt = YoutubeExplode();
    try {
      final started = DateTime.now();
      logLine('[import] phase: fetching stream info for $videoIdOrUrl');
      onPhase?.call('Fetching stream info…');
      Object? firstError;
      StreamManifest? manifest;
      for (final requireWatchPage in [false, true]) {
        try {
          manifest = await yt.videos.streams
              .getManifest(videoIdOrUrl)
              .timeout(const Duration(seconds: 40));
          logLine(
              '[import] manifest OK in ${DateTime.now().difference(started).inMilliseconds}ms');
          break;
        } catch (e) {
          firstError ??= e;
          logLine(
              '[import] manifest FAILED: ${e.runtimeType}: $e');
        }
      }
      }
      if (manifest == null) {
        throw firstError ?? Exception("Couldn't read this video's streams");
      }

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        logLine('[import] no audio streams in manifest');
        throw Exception('No audio stream available for this video');
      }
      final mp4 = audioStreams.where((s) => s.container.name == 'mp4');
      var info = mp4.isNotEmpty
          ? mp4.withHighestBitrate()
          : audioStreams.withHighestBitrate();
      var total = info.size.totalBytes;
      logLine(
          '[import] picked stream: ${info.container.name} ${info.bitrate.kiloBitsPerSecond}kbps size=$total url=${info.url.host}');

      onPhase?.call('Downloading audio…');
      onProgress?.call(0);

      // A stream URL that 403'd stays 403'd — googlevideo issues one-shot
      // URLs. On failure, refetch the manifest (fast, no watch page) for a
      // fresh URL and try again before falling back.
      Uint8List? bytes;
      Object? directError;
      for (var tryNo = 1; tryNo <= 3 && bytes == null; tryNo++) {
        try {
          logLine('[import] DIRECT attempt $tryNo…');
          final t = DateTime.now();
          bytes = await _downloadDirect(info.url, total, onProgress);
          logLine(
              '[import] DIRECT OK: ${bytes.length} bytes in ${DateTime.now().difference(t).inMilliseconds}ms');
        } catch (e) {
          directError = e;
          logLine(
              '[import] DIRECT attempt $tryNo FAILED: ${e.runtimeType}: $e');
          if (tryNo == 3) break;
          logLine('[import] refetching manifest for a fresh stream URL…');
          onPhase?.call('Refreshing stream link…');
          try {
            final fresh = await yt.videos.streams
                .getManifest(videoIdOrUrl)
                .timeout(const Duration(seconds: 40));
            final freshAudio = fresh.audioOnly;
            if (freshAudio.isEmpty) break;
            final freshMp4 =
                freshAudio.where((s) => s.container.name == 'mp4');
            info = freshMp4.isNotEmpty
                ? freshMp4.withHighestBitrate()
                : freshAudio.withHighestBitrate();
            total = info.size.totalBytes;
            onPhase?.call('Downloading audio…');
            logLine('[import] fresh URL: tag=${info.tag} host=${info.url.host}');
          } catch (e2) {
            logLine(
                '[import] fresh manifest FAILED: ${e2.runtimeType}: $e2');
            break;
          }
        }
      }

      if (bytes == null) {
        logLine(
            '[import] DIRECT exhausted (${directError?.runtimeType}) — falling back to library stream');
        logLine('[import] trying LIBRARY stream…');
        final t = DateTime.now();
        bytes = await _downloadViaLibrary(yt, info, total, onProgress);
        logLine(
            '[import] LIBRARY OK: ${bytes.length} bytes in ${DateTime.now().difference(t).inMilliseconds}ms');
      }

      if (total > 0 && (bytes.length - total).abs() > total * 0.02) {
        throw Exception(
            'Download was incomplete (${bytes.length} of $total bytes) — try again');
      }
      onProgress?.call(1);
      logLine(
          '[import] download COMPLETE: ${bytes.length} bytes, total ${DateTime.now().difference(started).inMilliseconds}ms');
      return bytes;
    } finally {
      yt.close();
    }
  }

  /// Direct HTTP download of the stream URL: real progress callbacks and a
  /// receive timeout that acts as a stall detector.
  ///
  /// Headers and range handling mirror youtube_explode's own HTTP client,
  /// which googlevideo.com requires (a bare Dart request gets 403).
  Future<Uint8List> _downloadDirect(
    Uri url,
    int expected,
    void Function(double progress)? onProgress,
  ) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      responseType: ResponseType.bytes,
      headers: {
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36',
        'cookie': 'CONSENT=YES+cb',
        'accept': '*/*',
        'accept-language': 'en-US,en;q=0.5',
      },
      validateStatus: (s) => s == 200 || s == 206,
    ));

    // Same range convention as youtube_explode: query param for most
    // streams, Range header only for the ANDROID client.
    final useHeaderRange = url.queryParameters['c'] == 'ANDROID';
    final Uri requestUrl = useHeaderRange
        ? url
        : url.replace(
            queryParameters: {...url.queryParameters, 'range': '0-'});
    logLine(
        '[import] direct GET range=${useHeaderRange ? 'header' : 'query'} host=${url.host}');

    var lastLoggedPct = -10;
    var lastEmittedPct = -1;
    final t = DateTime.now();
    try {
      final response = await dio.get<List<int>>(
        requestUrl.toString(),
        options: useHeaderRange
            ? Options(headers: {'Range': 'bytes=0-'})
            : Options(),
        onReceiveProgress: (got, total) {
          final effective = total > 0 ? total : expected;
          if (effective > 0) {
            final pct = (got / effective * 100).floor();
            // Throttle: one UI update per whole percent, not per 8KB chunk.
            if (pct != lastEmittedPct) {
              lastEmittedPct = pct;
              onProgress?.call((got / effective).clamp(0.0, 1.0));
            }
            if (pct >= lastLoggedPct + 10) {
              lastLoggedPct = pct - (pct % 10);
              logLine(
                  '[import] direct: $pct% ($got/$effective) ${DateTime.now().difference(t).inMilliseconds}ms');
            }
          }
        },
      );
      final data = response.data;
      logLine(
          '[import] direct response: status=${response.statusCode} bytes=${data?.length ?? 0} in ${DateTime.now().difference(t).inMilliseconds}ms');
      if (data == null || data.isEmpty) {
        throw Exception('Empty response from YouTube');
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      String snippet = '';
      if (body is List<int> && body.isNotEmpty) {
        snippet = String.fromCharCodes(body.take(400));
      } else if (body is String && body.isNotEmpty) {
        snippet = body.substring(0, body.length.clamp(0, 400));
      }
      logLine('[import] direct HTTP $status body: $snippet');
      rethrow;
    }
  }

  /// Fallback: youtube_explode's stream, guarded by a stall watchdog.
  Future<Uint8List> _downloadViaLibrary(
    YoutubeExplode yt,
    AudioStreamInfo info,
    int expected,
    void Function(double progress)? onProgress,
  ) async {
    final completer = Completer<Uint8List>();
    final chunks = <int>[];
    Timer? watchdog;
    Timer? heartbeat;
    var chunkCount = 0;
    var lastLoggedPct = -10;
    final t = DateTime.now();

    void arm() {
      watchdog?.cancel();
      watchdog = Timer(const Duration(seconds: 60), () {
        logLine(
            '[import] library stream STALLED: $chunkCount chunks, ${chunks.length} bytes after ${DateTime.now().difference(t).inMilliseconds}ms — aborting');
        if (!completer.isCompleted) {
          completer.completeError(Exception(
              'Download stalled — check your connection and try again'));
        }
      });
    }

    arm();
    heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
      logLine(
          '[import] library: waiting… $chunkCount chunks, ${chunks.length} bytes, ${DateTime.now().difference(t).inSeconds}s elapsed');
    });
    final sub = yt.videos.streams.get(info).listen(
      (chunk) {
        if (chunkCount == 0) {
          logLine(
              '[import] library: first chunk after ${DateTime.now().difference(t).inMilliseconds}ms (${chunk.length} bytes)');
          heartbeat?.cancel();
        }
        arm();
        chunkCount++;
        chunks.addAll(chunk);
        if (expected > 0) {
          onProgress?.call((chunks.length / expected).clamp(0.0, 1.0));
          final pct = (chunks.length / expected * 100).floor();
          if (pct >= lastLoggedPct + 25) {
            lastLoggedPct = pct - (pct % 25);
            logLine(
                '[import] library: $pct% ($chunkCount chunks) ${DateTime.now().difference(t).inMilliseconds}ms');
          }
        }
      },
      onError: (Object e) {
        logLine(
            '[import] library stream ERROR: ${e.runtimeType}: $e after ${DateTime.now().difference(t).inMilliseconds}ms');
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        logLine(
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
      heartbeat.cancel();
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
