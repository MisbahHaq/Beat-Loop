import 'dart:io';
import 'package:beatloop/Services/link_import_service.dart';

Future<void> main() async {
  final service = LinkImportService();
  print('=== YouTube link test ===');
  try {
    final bytes = await service.downloadAudio(
      videoIdOrUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      onPhase: (p) => print('[phase] $p'),
      onProgress: (p) => print('[progress] ${(p * 100).toStringAsFixed(0)}%'),
    );
    print('YOUTUBE RESULT: ${bytes.length} bytes');
  } catch (e) {
    print('YOUTUBE FAILED: ${e.runtimeType}: $e');
  }

  exit(0);
}
