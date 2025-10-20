import 'models.dart';

class PlaylistService {
  static List<Playlist> initializePlaylists(List<Song> allSongs) {
    final List<String> hasanRaheemTitles = [
      'Dard',
      'Accusations',
      'Post You',
      'E X E S',
      'Kanwal',
      'Faaslay',
      'Kaleji',
      'Dewana',
      'No More Care',
      'Dil K Parday',
      'Fly With Me',
      'Mehbooba',
      'Fana',
      'Pal Pal',
      'Dil Fareb',
      'Tareekhi',
      'IDK',
      'Fly With Me',
      'Hungama',
      'Bayaan',
      'Wishes',
      'You',
      'Memories',
      'Radha',
      'Aarzu',
      'Peanut Butter',
      'Dil Ruba',
      'Faltu Pyar',
      'Joona',
      'Disconnect',
      'Turri Jandi',
      'Roop',
    ];

    return [
      Playlist(
        name: 'Hasan Raheem',
        songs:
            allSongs.where((s) => hasanRaheemTitles.contains(s.title)).toList()
              ..sort((a, b) => hasanRaheemTitles
                  .indexOf(a.title)
                  .compareTo(hasanRaheemTitles.indexOf(b.title))),
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
