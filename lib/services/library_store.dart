import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

/// Keeps the user's own songs. Files are copied into the app's private
/// folder so they keep working after the picker's temp cache is cleared.
class LibraryStore {
  static const _key = 'songs_v1';
  final List<Song> songs = [];

  Future<Directory> _dir(String name) async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'SingTunado', name));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Directory> recordingsDir() => _dir('recordings');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    songs.clear();
    if (raw == null) return;
    for (final j in (jsonDecode(raw) as List)) {
      final s = Song.fromJson(j as Map<String, dynamic>);
      if (await File(s.audioPath).exists()) songs.add(s);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(songs.map((s) => s.toJson()).toList()));
  }

  Future<String> _copyIn(String src, String folder) async {
    final dir = await _dir(folder);
    final name = '${DateTime.now().microsecondsSinceEpoch}_${p.basename(src)}';
    final dest = p.join(dir.path, name);
    await File(src).copy(dest);
    return dest;
  }

  /// Lets the user pick audio files they own. Returns how many were added.
  Future<int> addSongs() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'],
      allowMultiple: true,
    );
    if (res == null) return 0;
    var added = 0;
    for (final f in res.files) {
      final path = f.path;
      if (path == null) continue;
      final stored = await _copyIn(path, 'songs');
      songs.add(Song(
        id: DateTime.now().microsecondsSinceEpoch.toString() + added.toString(),
        title: p.basenameWithoutExtension(f.name),
        audioPath: stored,
      ));
      added++;
    }
    await _save();
    return added;
  }

  /// Attach a synced-lyrics (.lrc) file to a song.
  Future<bool> attachLyrics(Song song) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc', 'txt'],
    );
    final path = res?.files.single.path;
    if (path == null) return false;
    song.lrcPath = await _copyIn(path, 'lyrics');
    await _save();
    return true;
  }

  Future<void> rename(Song song, String title) async {
    song.title = title;
    await _save();
  }

  Future<void> remove(Song song) async {
    songs.remove(song);
    for (final path in [song.audioPath, song.lrcPath]) {
      if (path == null) continue;
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await _save();
  }
}
