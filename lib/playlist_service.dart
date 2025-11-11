import 'models.dart';

class PlaylistService {
  static List<Playlist> initializePlaylists(List<Song> allSongs) {
    return [
      Playlist(
        name: 'Hasan Raheem',
        songs:
            allSongs.where((s) => s.artist.contains('Hasan Raheem')).toList(),
      ),
      Playlist(
        name: 'Afusic',
        songs: allSongs.where((s) => s.artist.contains('Afusic')).toList(),
      ),
      Playlist(
        name: 'Talwiinder',
        songs: allSongs.where((s) => s.artist.contains('Talwiinder')).toList(),
      ),
      Playlist(
        name: 'Uzair Jaswal',
        songs: allSongs.where((s) => s.artist == 'Uzair Jaswal').toList(),
      ),
      Playlist(
        name: 'AMVs',
        songs: allSongs
            .where((s) =>
                s.title == 'In Love With an Angel' ||
                s.title == 'Gurenge' ||
                s.title == 'Unravel' ||
                s.title == 'Namae Yobu' ||
                s.title == 'Catch Fire' ||
                s.title == 'End Of Me' ||
                s.title == 'Youre My Escape' ||
                s.title == 'Love and Honor' ||
                s.title == 'Its Not Over' ||
                s.title == 'Unravel' ||
                s.title == 'Call Me Now' ||
                s.title == 'End Of Heroes')
            .toList(),
      ),
      Playlist(
        name: 'All Songs',
        songs: allSongs.toList()..sort((a, b) => a.title.compareTo(b.title)),
      ),
    ];
  }
}
