import 'models.dart';

class PlaylistService {
  static List<Playlist> initializePlaylists(List<Song> allSongs) {
    return [
      Playlist(
        name: 'Hasan Raheem',
        songs: allSongs
            .where((s) =>
                s.title == 'Dard' ||
                s.title == 'Accusations' ||
                s.title == 'Post You' ||
                s.title == 'E X E S' ||
                s.title == 'Back Ke' ||
                s.title == 'Kanwal' ||
                s.title == 'Faaslay' ||
                s.title == 'Kaleji' ||
                s.title == 'Dewana' ||
                s.title == 'No More Care' ||
                s.title == 'Dil K Parday' ||
                s.title == 'Fly With Me' ||
                s.title == 'Mehbooba' ||
                s.title == 'Fana' ||
                s.title == 'Pal Pal' ||
                s.title == 'Dil Fareb' ||
                s.title == 'Tareekhi' ||
                s.title == 'IDK' ||
                s.title == 'Fly With Me' ||
                s.title == 'Hungama' ||
                s.title == 'Aarzu' ||
                s.title == 'Peanut Butter' ||
                s.title == 'Dil Ruba' ||
                s.title == 'Faltu Pyar' ||
                s.title == 'Bayaan' ||
                s.title == 'Wishes' ||
                s.title == 'You' ||
                s.title == 'Joona' ||
                s.title == 'Disconnect' ||
                s.title == 'Turri Jandi' ||
                s.title == 'Roop' ||
                s.title == 'Memories' ||
                s.title == 'Radha')
            .toList(),
      ),
      Playlist(
        name: 'Uzair Jaswal',
        songs: allSongs
            .where((s) => s.image == 'assets/images/uzair.jpg')
            .toList(),
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
