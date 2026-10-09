# Nine Men's Morris

An ancient duel of mills and cunning — Flutter, per the Wajiha game-factory
master rules. Carved-stone art direction ("Lapidary Archaeological Interface"):
weathered sandstone board with chisel-cut grooves, cast-bronze and carved-bone
tokens with verdigris patina, parchment panels with letterpressed type, all
under a warm museum spotlight.

Package: `com.gameswajiha.ninemensmorris`

## Structure

- `lib/engine/` — pure deterministic rules engine (`morris.dart` board
  topology, `engine.dart` moves/mills/captures/draws, `ai.dart` minimax bot
  with Easy/Medium/Hard per RULES.md §11)
- `lib/state/` — `GameController` (turns, undo, hints, draws, pause/resume,
  persistence), `SettingsStore`, `StatsStore` (shared_preferences)
- `lib/audio/` — `audioplayers` sound manager; all SFX + music loops
  synthesized in `tools/gen_audio.py` (stone taps, bronze clinks)
- `lib/ui/` — design system (`lapidary.dart`), carved widgets, the
  pseudo-3D `BoardPainter`, and screens: menu, new-game, game, pause overlay,
  settings, how-to, game-over
- `test/engine_test.dart` — RULES.md §13 conformance tests

## Audio

Regenerate with `python3 tools/gen_audio.py` (needs numpy). Output:
`assets/sounds/*.wav`.

## Build

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
