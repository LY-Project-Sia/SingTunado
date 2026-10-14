/// One timed line of lyrics.
class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration time;
  final String text;
}

final _tag = RegExp(r'\[(\d+):(\d+)(?:[.:](\d+))?\]');

/// Parses standard .lrc text ("[01:23.45] words"). Metadata tags such as
/// [ar:Artist] are ignored. Supports several time tags on one line.
List<LyricLine> parseLrc(String source) {
  final lines = <LyricLine>[];
  for (final raw in source.split(RegExp(r'\r?\n'))) {
    final matches = _tag.allMatches(raw).toList();
    if (matches.isEmpty) continue;
    final text = raw.substring(matches.last.end).trim();
    for (final m in matches) {
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final frac = m.group(3);
      var ms = 0;
      if (frac != null) {
        ms = switch (frac.length) {
          1 => int.parse(frac) * 100,
          2 => int.parse(frac) * 10,
          _ => int.parse(frac.substring(0, 3)),
        };
      }
      lines.add(LyricLine(
        Duration(minutes: min, seconds: sec, milliseconds: ms),
        text,
      ));
    }
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}

/// Index of the line being sung at [position], or -1 before the first line.
int currentLyricIndex(List<LyricLine> lines, Duration position) {
  var lo = 0, hi = lines.length - 1, ans = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (lines[mid].time <= position) {
      ans = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return ans;
}
