import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/library_store.dart';
import '../theme.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _store = LibraryStore();
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _add() async {
    final n = await _store.addSongs();
    if (!mounted) return;
    setState(() {});
    if (n > 0) _toast('Added $n song${n == 1 ? '' : 's'}');
  }

  Future<void> _rename(Song s) async {
    final c = TextEditingController(text: s.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename song'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    await _store.rename(s, title);
    if (mounted) setState(() {});
  }

  Future<void> _delete(Song s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove song?'),
        content: Text('"${s.title}" will be removed from SingTunado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    await _store.remove(s);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final songs = _store.songs
        .where((s) => s.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/icon.png', height: 34, width: 34),
          ),
          const SizedBox(width: 10),
          const GradientText('SingTunado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.library_add),
        label: const Text('Add songs'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search your songs',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Brand.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: songs.isEmpty
                    ? _Empty(hasSongs: _store.songs.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: songs.length,
                        itemBuilder: (_, i) => _tile(songs[i]),
                      ),
              ),
            ]),
    );
  }

  Widget _tile(Song s) {
    return Card(
      color: Brand.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Brand.purple,
          child: Icon(Icons.music_note, color: Colors.white),
        ),
        title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(s.lrcPath != null ? 'Synced lyrics ✓' : 'No lyrics attached'),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlayerScreen(song: s, store: _store)),
          );
          if (mounted) setState(() {});
        },
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'lrc') {
              final ok = await _store.attachLyrics(s);
              if (ok && mounted) {
                setState(() {});
                _toast('Lyrics attached');
              }
            } else if (v == 'rename') {
              _rename(s);
            } else if (v == 'delete') {
              _delete(s);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'lrc', child: Text('Attach .lrc lyrics')),
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasSongs});
  final bool hasSongs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.mic_external_on, size: 64, color: Brand.magenta),
          const SizedBox(height: 16),
          Text(
            hasSongs ? 'No songs match your search.' : 'Your song list is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!hasSongs) ...[
            const SizedBox(height: 8),
            const Text(
              'Tap "Add songs" to pick backing tracks you own or are '
              'licensed to use (mp3, m4a, wav, flac, ogg). Attach a .lrc '
              'file to a song to get synced lyrics.',
              textAlign: TextAlign.center,
            ),
          ],
        ]),
      ),
    );
  }
}
