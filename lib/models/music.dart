class Track {
  final String id;
  final String title;
  final String artist;
  final Duration duration;

  final String? uri;
  final String? imageUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.uri,
    this.imageUrl,
  });
}

class Playlist {
  final String id;
  final String name;
  final String subtitle;

  /// ✅ add this for playlist artwork (Spotify playlist image)
  final String? imageUrl;

  final List<Track> track;

  const Playlist({
    required this.id,
    required this.name,
    required this.subtitle,
    this.imageUrl,
    required this.track,
  });
}

class Artist {
  final String id;
  final String name;
  final String subtitle;

  const Artist({
    required this.id,
    required this.name,
    required this.subtitle,
  });
}
