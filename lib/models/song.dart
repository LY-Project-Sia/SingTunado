class Song {
  Song({required this.id, required this.title, required this.audioPath, this.lrcPath});

  final String id;
  String title;
  String audioPath;
  String? lrcPath;

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'audioPath': audioPath, 'lrcPath': lrcPath};

  factory Song.fromJson(Map<String, dynamic> j) => Song(
        id: j['id'] as String,
        title: j['title'] as String,
        audioPath: j['audioPath'] as String,
        lrcPath: j['lrcPath'] as String?,
      );
}
