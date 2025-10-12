// Song Model
class Song {
  final String path;
  final String title;
  final String image;
  Song({required this.path, required this.title, required this.image});
}

// Playlist Model
class Playlist {
  final String name;
  final List<Song> songs;
  Playlist({required this.name, required this.songs});
}
