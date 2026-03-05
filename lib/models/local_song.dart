class LocalSong {
  final int? id;
  final String path;
  final String title;
  final String artist;
  final String? coverPath;

  LocalSong({
    this.id,
    required this.path,
    required this.title,
    this.artist = "Unknown Artist",
    this.coverPath
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'title': title,
      'artist': artist,
      'coverPath': coverPath,
    };
  }

  factory LocalSong.fromMap(Map<String, dynamic> map) {
    return LocalSong(
      id: map['id'],
      path: map['path'],
      title: map['title'],
      artist: map['artist'] ?? "Unknown Artist",
      coverPath: map['coverPath'],
    );
  }
}