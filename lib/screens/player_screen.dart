import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../models/lrc.dart';
import '../models/song.dart';
import '../services/library_store.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.song, required this.store});
  final Song song;
  final LibraryStore store;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const double _itemH = 64;

  final _player = AudioPlayer();
  final _recorder = AudioRecorder();
  final _scroll = ScrollController();

  List<LyricLine> _lyrics = [];
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _playing = false;
  bool _recording = false;
  int _lineIdx = -1;
  double _level = 0;
  int _activeTicks = 0;
  int _singTicks = 0;
  String? _error;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Amplitude>? _ampSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final lrc = widget.song.lrcPath;
      if (lrc != null && await File(lrc).exists()) {
        _lyrics = parseLrc(await File(lrc).readAsString());
      }
      await _player.setFilePath(widget.song.audioPath);
      _posSub = _player.positionStream.listen(_onPosition);
      _durSub = _player.durationStream.listen((d) {
        if (d != null && mounted) setState(() => _dur = d);
      });
      _stateSub = _player.playerStateStream.listen((s) async {
        if (!mounted) return;
        setState(() => _playing = s.playing);
        if (s.processingState == ProcessingState.completed) {
          await _player.pause();
          await _player.seek(Duration.zero);
          if (_recording) await _stopRecording();
        }
      });
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open this song: $e');
    }
  }

  void _onPosition(Duration pos) {
    if (!mounted) return;
    final idx = currentLyricIndex(_lyrics, pos);
    setState(() {
      _pos = pos;
      if (idx != _lineIdx) {
        _lineIdx = idx;
        _scrollToLine();
      }
    });
  }

  void _scrollToLine() {
    if (!_scroll.hasClients || _lineIdx < 0) return;
    final target = (_lineIdx * _itemH).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await _player.pause();
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      _toast('Microphone permission is needed to record.');
      return;
    }
    final dir = await widget.store.recordingsDir();
    final win = Platform.isWindows;
    final safe = widget.song.title.replaceAll(RegExp(r'[^\w\- ]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = p.join(dir.path, '${safe}_$stamp.${win ? 'wav' : 'm4a'}');

    await _recorder.start(
      RecordConfig(encoder: win ? AudioEncoder.wav : AudioEncoder.aacLc),
      path: path,
    );
    _activeTicks = 0;
    _singTicks = 0;
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((a) {
      final db = a.current; // roughly -160 .. 0 dBFS
      final lineActive = _lyrics.isEmpty
          ? true
          : (_lineIdx >= 0 && _lyrics[_lineIdx].text.isNotEmpty);
      if (lineActive) {
        _activeTicks++;
        if (db > -35) _singTicks++;
      }
      if (mounted) setState(() => _level = ((db + 60) / 60).clamp(0.0, 1.0));
    });

    await _player.seek(Duration.zero);
    await _player.play();
    if (mounted) setState(() => _recording = true);
  }

  Future<void> _stopRecording() async {
    await _ampSub?.cancel();
    _ampSub = null;
    final path = await _recorder.stop();
    final score =
        _activeTicks == 0 ? 0 : (_singTicks * 100 / _activeTicks).round();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _level = 0;
    });
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nice singing!'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          GradientText('$score%',
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900)),
          const Text('Voice activity score'),
          const SizedBox(height: 4),
          const Text(
            'Measures how much you sang during lyric lines. It does not judge pitch.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          if (path != null) ...[
            const SizedBox(height: 12),
            SelectableText('Saved to:\n$path', style: const TextStyle(fontSize: 11)),
          ],
        ]),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _ampSub?.cancel();
    _scroll.dispose();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.song.title, overflow: TextOverflow.ellipsis)),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : Column(children: [
              Expanded(child: _lyricsView()),
              if (_recording) _meter(),
              _controls(),
            ]),
    );
  }

  Widget _lyricsView() {
    if (_lyrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lyrics_outlined, size: 56, color: Brand.blue),
            const SizedBox(height: 12),
            const Text(
              'No synced lyrics for this song.\nGo back, open the ⋮ menu and choose "Attach .lrc lyrics".',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final pad = (c.maxHeight / 2 - _itemH / 2).clamp(0.0, double.infinity);
      return ListView.builder(
        controller: _scroll,
        itemExtent: _itemH,
        padding: EdgeInsets.symmetric(vertical: pad, horizontal: 20),
        itemCount: _lyrics.length,
        itemBuilder: (_, i) {
          final line = _lyrics[i];
          final text = line.text.isEmpty ? '♪' : line.text;
          final current = i == _lineIdx;
          return Center(
            child: current
                ? GradientText(text,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  )
                : Text(text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.white38)),
          );
        },
      );
    });
  }

  Widget _meter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(children: [
        const Icon(Icons.mic, color: Brand.magenta),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _level,
              minHeight: 10,
              backgroundColor: Brand.surface,
              color: Brand.orange,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _controls() {
    final maxMs = _dur.inMilliseconds.toDouble();
    final posMs = _pos.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(_fmt(_pos)),
            Expanded(
              child: Slider(
                value: posMs,
                max: maxMs > 0 ? maxMs : 1.0,
                activeColor: Brand.magenta,
                onChanged: _recording
                    ? null
                    : (v) => _player.seek(Duration(milliseconds: v.round())),
              ),
            ),
            Text(_fmt(_dur)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              iconSize: 40,
              onPressed: _recording ? null : () => _player.seek(Duration.zero),
              icon: const Icon(Icons.replay),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              iconSize: 44,
              onPressed: _recording ? null : _togglePlay,
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _toggleRecord,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _recording ? null : Brand.gradient,
                  color: _recording ? Colors.redAccent : null,
                ),
                child: Icon(_recording ? Icons.stop : Icons.mic, size: 32, color: Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            _recording
                ? 'Recording... tap stop to finish'
                : 'Tap the mic to sing and record (use headphones for best results)',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
