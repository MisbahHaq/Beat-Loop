// Song Model
class Song {
  final String path;
  final String title;
  final String image;
  final String artist;
  Song(
      {required this.path,
      required this.title,
      required this.image,
      required this.artist});
}

// Playlist Model
class Playlist {
  final String name;
  final List<Song> songs;
  final String? image;
  Playlist({required this.name, required this.songs, this.image});
}
