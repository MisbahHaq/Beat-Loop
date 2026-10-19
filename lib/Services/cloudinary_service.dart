import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class CloudinaryService {
  static const String cloudName = 'drcpslfrz';
  static const String uploadPreset = 'beatloop_mobile';
  static const String catalogPublicId = 'beatloop_imports.json';

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 180),
  ));

  static String _cloudinaryError(Response response) {
    final data = response.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['message']?.toString() ?? 'Cloudinary upload failed';
    }
    return 'Cloudinary upload failed (${response.statusCode})';
  }

  static Future<String> uploadBytes({
    required List<int> bytes,
    required String filename,
    required String resourceType,
    String? publicId,
    void Function(double progress)? onProgress,
  }) async {
    final url =
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
    final fields = <String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'upload_preset': uploadPreset,
    };
    if (publicId != null) fields['public_id'] = publicId;

    try {
      final response = await _dio.post(
        url,
        data: FormData.fromMap(fields),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call((sent / total).clamp(0.0, 1.0));
        },
      );
      final secureUrl = response.data['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary did not return a URL');
      }
      return secureUrl;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(_cloudinaryError(e.response!));
      throw Exception('Upload failed: ${e.message ?? 'network error'}');
    }
  }

  static Future<String> uploadFile({
    required File file,
    required String resourceType,
    void Function(double progress)? onProgress,
  }) async {
    return uploadBytes(
      bytes: await file.readAsBytes(),
      filename: file.uri.pathSegments.last,
      resourceType: resourceType,
      onProgress: onProgress,
    );
  }

  static List<String> get _catalogUrls => [
        'https://res.cloudinary.com/$cloudName/raw/upload/beatloop/$catalogPublicId',
        'https://res.cloudinary.com/$cloudName/raw/upload/$catalogPublicId',
      ];

  static Future<Map<String, dynamic>?> fetchCatalog() async {
    for (final base in _catalogUrls) {
      try {
        final response = await _dio.get(
          '$base?cb=${DateTime.now().millisecondsSinceEpoch}',
          options: Options(
            validateStatus: (status) =>
                status != null && status < 500 && status != 401,
          ),
        );
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic>) return data;
          if (data is String && data.trim().isNotEmpty) {
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic>) return decoded;
          }
        }
      } catch (_) {
        // Try the next URL candidate.
      }
    }
    return null;
  }

  static Future<void> saveCatalog(Map<String, dynamic> catalog) async {
    await uploadBytes(
      bytes: utf8.encode(jsonEncode(catalog)),
      filename: catalogPublicId,
      resourceType: 'raw',
      publicId: catalogPublicId,
    );
  }
}
