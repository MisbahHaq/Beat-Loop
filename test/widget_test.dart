import 'package:beatloop/Services/link_import_service.dart';
import 'package:beatloop/models.dart';
import 'package:beatloop/widgets/song_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies YouTube and Spotify links', () {
    expect(
        LinkImportService.isYouTubeLink('https://www.youtube.com/watch?v=abc'),
        isTrue);
    expect(LinkImportService.isYouTubeLink('https://youtu.be/abc'), isTrue);
    expect(
        LinkImportService.isYouTubeLink('https://m.youtube.com/watch?v=abc'),
        isTrue);
    expect(
        LinkImportService.isSpotifyLink('https://open.spotify.com/track/abc'),
        isTrue);
    expect(LinkImportService.isSpotifyLink('https://example.com/x'), isFalse);
    expect(LinkImportService.isYouTubeLink('https://example.com/x'), isFalse);
  });

  test('song image provider routes url, file and asset paths', () {
    expect(songImageProvider('https://res.cloudinary.com/x/y.jpg'),
        isA<NetworkImage>());
    expect(songImageProvider('http://example.com/a.png'), isA<NetworkImage>());
    expect(songImageProvider('assets/images/exes.jpg'), isA<AssetImage>());
    expect(songImageProvider('/data/user/0/app/art.jpg'), isA<FileImage>());
  });

  test('Song keeps optional sourceUrl', () {
    final imported = Song(
      path: 'https://res.cloudinary.com/x/video/upload/song.m4a',
      title: 'Test Song',
      image: 'assets/images/0016.jpg',
      artist: 'Someone',
      sourceUrl: 'https://youtu.be/abc',
    );
    expect(imported.sourceUrl, 'https://youtu.be/abc');

    final builtin = Song(
      path: 'https://res.cloudinary.com/x/video/upload/song.mp3',
      title: 'Dard',
      image: 'assets/images/exes.jpg',
      artist: 'Hasan Raheem',
    );
    expect(builtin.sourceUrl, isNull);
  });

  test('audio file names are filesystem safe', () {
    final service = LinkImportService();
    final name = service.audioFileName('Weird: Title?/ "Quoted" *');
    expect(name.endsWith('.m4a'), isTrue);
    expect(RegExp(r'[^\w.\-]').hasMatch(name), isFalse);
  });
}
