import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../songs_data.dart';
import 'cloudinary_service.dart';

class CatalogService {
  static const String _cacheKey = 'beatloop_imported_catalog_v1';

  static final List<Song> _imported = [];
  static List<Song> get importedSongs => List.unmodifiable(_imported);

  /// Full library: hardcoded catalog + songs imported from links.
  static List<Song> get library => [...allSongs, ..._imported];

  static Future<void> load() async {
    _imported.clear();
    Map<String, dynamic>? catalog;
    try {
      catalog = await CloudinaryService.fetchCatalog();
      if (catalog != null) await _writeCache(catalog);
    } catch (_) {
      // Fall through to the local cache.
    }
    catalog ??= await _readCache();
    if (catalog != null) _parseInto(catalog);
  }

  static Future<void> addSong({
    required String path,
    required String title,
    required String image,
    required String artist,
    String? sourceUrl,
  }) async {
    _imported.add(Song(
      path: path,
      title: title,
      image: image,
      artist: artist,
      sourceUrl: sourceUrl,
    ));

    final catalog = {
      'version': 1,
      'songs': _imported
          .map((s) => <String, dynamic>{
                'path': s.path,
                'title': s.title,
                'image': s.image,
                'artist': s.artist,
                if (s.sourceUrl != null) 'sourceUrl': s.sourceUrl,
              })
          .toList(),
    };
    try {
      await CloudinaryService.saveCatalog(catalog);
      await _writeCache(catalog);
    } catch (e) {
      // Roll back so a retry doesn't add a duplicate; the UI gets the error.
      _imported.removeLast();
      rethrow;
    }
  }

  static void _parseInto(Map<String, dynamic> catalog) {
    final songs = catalog['songs'];
    if (songs is! List) return;
    for (final raw in songs) {
      if (raw is! Map) continue;
      final path = raw['path']?.toString() ?? '';
      final title = raw['title']?.toString() ?? '';
      final image = raw['image']?.toString() ?? '';
      final artist = raw['artist']?.toString() ?? '';
      final sourceUrl = raw['sourceUrl']?.toString();
      if (path.isEmpty || title.isEmpty) continue;
      _imported.add(Song(
        path: path,
        title: title,
        image: image.isEmpty ? 'assets/images/0016.jpg' : image,
        artist: artist.isEmpty ? 'Unknown artist' : artist,
        sourceUrl: sourceUrl,
      ));
    }
  }

  static Future<void> _writeCache(Map<String, dynamic> catalog) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(catalog));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
