import '../models/music.dart';

class DemoData {
  final tracks = <Track>[
    Track(id: 't1', title: 'Midnight City', artist: 'M83', duration: Duration(minutes: 4, seconds: 3)),
    Track(id: 't2', title: 'Sunset Lover', artist: 'Petit Biscuit', duration: Duration(minutes: 3, seconds: 58)),
    Track(id: 't3', title: 'Blinding Lights', artist: 'The Weeknd', duration: Duration(minutes: 3, seconds: 20)),
    Track(id: 't4', title: 'After Dark', artist: 'Mr.Kitty', duration: Duration(minutes: 4, seconds: 18)),
    Track(id: 't5', title: 'Time', artist: 'Hans Zimmer', duration: Duration(minutes: 4, seconds: 35)),
    Track(id: 't6', title: 'Nights', artist: 'Frank Ocean', duration: Duration(minutes: 5, seconds: 7)),
    Track(id: 't7', title: 'Stay', artist: 'The Kid LAROI', duration: Duration(minutes: 2, seconds: 21)),
    Track(id: 't8', title: 'Heat Waves', artist: 'Glass Animals', duration: Duration(minutes: 3, seconds: 59)),
  ];

  final artists = <Artist>[
    const Artist(id: 'a1', name: 'M83', subtitle: 'Electronic • Indie'),
    const Artist(id: 'a2', name: 'The Weeknd', subtitle: 'Pop • R&B'),
    const Artist(id: 'a3', name: 'Hans Zimmer', subtitle: 'Soundtracks'),
    const Artist(id: 'a4', name: 'Frank Ocean', subtitle: 'R&B • Alternative'),
  ];

  List<Playlist> get playlists => [
    Playlist(id: 'p1', name: 'Today’s Mix', subtitle: 'Based on your taste', track: [tracks[1], tracks[2], tracks[3]]),
    Playlist(id: 'p2', name: 'Chill Vibes', subtitle: 'Lo-fi • Chill • Study', track: [tracks[0], tracks[4], tracks[5]]),
    Playlist(id: 'p3', name: 'Top Hits', subtitle: 'Trending now', track: [tracks[2], tracks[6], tracks[7]]),
    Playlist(id: 'p4', name: 'Focus Mode', subtitle: 'Deep work • No lyrics', track: [tracks[3], tracks[4], tracks[5]]),
    Playlist(id: 'p5', name: 'Night Drive', subtitle: 'Synth • Pop • Neon', track: [tracks[0], tracks[1], tracks[2]]),
  ];

}
