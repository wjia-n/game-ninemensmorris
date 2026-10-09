/// Central audio manager (audioplayers). All game audio flows through here.
///
/// Synthesized, game-specific sounds live in assets/sounds:
/// stone taps, bronze clinks, bell chimes, plus two ambient music loops.
/// Music + SFX toggles and volumes are owned by [SettingsStore] and applied
/// here; calls are safe no-ops when audio is unavailable.
library;

import 'package:audioplayers/audioplayers.dart';

import '../state/settings.dart';

class Sound {
  Sound._();
  static final Sound I = Sound._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    await _music.setReleaseMode(ReleaseMode.loop);
    await applyVolumes();
    SettingsStore.I.addListener(applyVolumes);
  }

  Future<void> applyVolumes() async {
    final s = SettingsStore.I;
    try {
      await _sfx.setVolume(s.sfxOn ? s.sfxVolume : 0.0);
      await _music.setVolume(s.musicOn ? s.musicVolume * 0.6 : 0.0);
    } catch (_) {}
  }

  Future<void> _play(String file) async {
    if (!SettingsStore.I.sfxOn) return;
    try {
      await _sfx.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }

  // --- one-shot SFX -------------------------------------------------------
  Future<void> click() => _play('click.wav'); // bronze tablet press
  Future<void> select() => _play('select.wav'); // token lifted
  Future<void> place() => _play('place.wav'); // stone token set down
  Future<void> move() => _play('move.wav'); // bronze token slides
  Future<void> fly() => _play('fly.wav'); // flying move
  Future<void> mill() => _play('mill.wav'); // mill formed
  Future<void> capture() => _play('capture.wav'); // enemy man removed
  Future<void> invalid() => _play('invalid.wav'); // illegal tap
  Future<void> undo() => _play('undo.wav'); // undo step
  Future<void> gameStart() => _play('game_start.wav');
  Future<void> win() => _play('win.wav');
  Future<void> lose() => _play('lose.wav');
  Future<void> draw() => _play('draw.wav');

  // --- music ----------------------------------------------------------------
  Future<void> menuMusic() async {
    if (!SettingsStore.I.musicOn) return;
    try {
      await _music.stop();
      await _music.play(AssetSource('sounds/music_menu.wav'));
    } catch (_) {}
  }

  Future<void> gameMusic() async {
    if (!SettingsStore.I.musicOn) return;
    try {
      await _music.stop();
      await _music.play(AssetSource('sounds/music_game.wav'));
    } catch (_) {}
  }

  Future<void> duckMusic() async {
    try {
      await _music.setVolume(SettingsStore.I.musicVolume * 0.25);
    } catch (_) {}
  }

  Future<void> unduckMusic() => applyVolumes();

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
  }

  void dispose() {
    SettingsStore.I.removeListener(applyVolumes);
    _sfx.dispose();
    _music.dispose();
  }
}
