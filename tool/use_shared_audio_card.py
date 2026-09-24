"""Replace the IELTS listening audio card with the shared AudioCard widget.

Both pages must render the exact same card (user 2026-09-24: "样式以及颜色都要
一样"). Keeping two hand-written copies is what let them drift apart, so the
IELTS page now uses lib/widgets/audio_card.dart too and keeps its original key.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
path = ROOT / "lib/features/ielts_listening/listening_layout.dart"
text = path.read_text()

open_marker = "          Container(\n              key: const ValueKey('listening-audio-card'),"
close_marker = "          const SizedBox(height: 22),"
start = text.index(open_marker)
end = text.index(close_marker, start)

replacement = """          AudioCard(
              cardKey: const ValueKey('listening-audio-card'),
              title: m['section'] ?? 'Section 3',
              subtitle: m['sectionDesc'] ?? m['ctx'],
              elapsed: clock(x.audio),
              total: m['audioDur'] ?? '07:00',
              progress: x.audio / 225,
              playing: x.playing,
              speedLabel: x.speed,
              speeds: const ['0.75X', '1X', '1.25X', '1.5X'],
              onSpeed: onSpeed,
              onToggle: onToggle,
              onSeek: (s) => onSeek(s.toDouble()),
              onRestart: () => onSeek(-225)),
"""

path.write_text(text[:start] + replacement + text[end:])
print(f"replaced {end - start} chars with shared AudioCard")
if "AudioCard(" not in path.read_text():
    sys.exit(1)
