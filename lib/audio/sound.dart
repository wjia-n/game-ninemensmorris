/// Central audio manager (audioplayers) for Nine Men's Morris.
///
/// Reliability design (every call is safe to repeat and safe to overlap):
/// - Clips are synthesized ancient-stone WAVs shipped in assets/sounds; each
///   is loaded into memory ONCE and cached, so playback never re-reads disk.
/// - A [_musicGen] generation counter serializes music start/stop: every
///   request bumps the generation, in-flight work from an older request
///   aborts, and the LATEST request always wins. Music is app-scoped and
///   never silently dies.
/// - SFX are serialized with a busy guard: overlapping calls queue behind a
///   short-lived lock instead of stomping the shared player.
/// - Lifecycle uses pause()/resume() so an interruption (call, backgrounding)
///   resumes exactly where it left off instead of restarting or dying.
/// - Every public method catches player errors; audio can never crash the app.
library;

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../state/settings.dart';

class Sound {
  Sound._();
  static final Sound I = Sound._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  Future<void>? _initFuture;

  // Cache: clip bytes loaded once.
  final Map<String, Uint8List> _cache = {};

  // Music state machine. [_musicGen] is bumped by every start/stop request;
  // async work checks it still owns the latest generation before touching
  // the player, so overlapping requests can never desync the music.
  int _musicGen = 0;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  // SFX serialization: at most one SFX player op in flight.
  bool _sfxBusy = false;
  final List<String> _sfxQueue = [];

  static const _clips = [
    'click.wav',
    'select.wav',
    'place.wav',
    'move.wav',
    'fly.wav',
    'mill.wav',
    'capture.wav',
    'invalid.wav',
    'undo.wav',
    'game_start.wav',
    'win.wav',
    'lose.wav',
    'draw.wav',
    'music_menu.wav',
    'music_game.wav',
  ];

  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
    SettingsStore.I.addListener(_onSettingsChanged);
    await applyVolumes();
  }

  /// Pre-build the clip cache off the critical path. Safe to call any time;
  /// the splash screen calls this while the loading line animates.
  Future<void> prewarm() async {
    if (_disposed) return;
    await init();
    // Load in the background so splash stays smooth.
    unawaited(Future(() async {
      for (final c in _clips) {
        if (_disposed) return;
        await _bytes(c);
        // Yield so we never hog the event loop.
        await Future.delayed(Duration.zero);
      }
    }));
  }

  Future<Uint8List?> _bytes(String file) async {
    var b = _cache[file];
    if (b != null) return b;
    try {
      final data = await rootBundle.load('assets/sounds/$file');
      b = data.buffer.asUint8List();
      _cache[file] = b;
      return b;
    } catch (_) {
      return null;
    }
  }

  void _onSettingsChanged() {
    if (_disposed) return;
    unawaited(applyVolumes());
    final s = SettingsStore.I;
    if (!s.musicOn) {
      unawaited(stopMusic());
    } else if (_currentTrack != null && !_pausedByLifecycle) {
      // Toggle back on: restart the current track rather than leaving silence.
      final t = _currentTrack;
      _currentTrack = null;
      if (t == 'menu') {
        unawaited(menuMusic());
      } else {
        unawaited(gameMusic());
      }
    }
  }

  Future<void> applyVolumes() async {
    final s = SettingsStore.I;
    try {
      await _sfx.setVolume(s.sfxOn ? s.sfxVolume : 0.0);
      await _music.setVolume(s.musicOn ? s.musicVolume * 0.6 : 0.0);
    } catch (_) {}
  }

  // --- SFX ------------------------------------------------------------------
  Future<void> _play(String file) async {
    if (!SettingsStore.I.sfxOn || _disposed) return;
    if (_sfxBusy) {
      // Queue behind the in-flight op; drop stale duplicates of the same clip.
      _sfxQueue.remove(file);
      _sfxQueue.add(file);
      if (_sfxQueue.length > 4) _sfxQueue.removeAt(0);
      return;
    }
    _sfxBusy = true;
    try {
      final bytes = await _bytes(file);
      if (bytes != null && SettingsStore.I.sfxOn && !_disposed) {
        await _sfx.stop();
        await _sfx.play(BytesSource(bytes));
      }
      // Drain one queued clip so rapid taps are not all swallowed.
      while (_sfxQueue.isNotEmpty && !_disposed) {
        final next = _sfxQueue.removeAt(0);
        final nb = await _bytes(next);
        if (nb != null && SettingsStore.I.sfxOn) {
          await _sfx.play(BytesSource(nb));
          break;
        }
      }
    } catch (_) {
    } finally {
      _sfxBusy = false;
    }
  }

  // --- one-shot SFX ----------------------------------------------------------
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

  // --- music ------------------------------------------------------------------
  Future<void> _startTrack(String track, String file) async {
    if (_disposed) return;
    final gen = ++_musicGen;
    try {
      if (_currentTrack == track && !SettingsStore.I.musicOn) {
        // fall through: settings handler already deals with toggles
      }
      if (_currentTrack == track) return;
      await _music.stop();
      if (gen != _musicGen || _disposed) return; // superseded
      final bytes = await _bytes(file);
      if (gen != _musicGen || _disposed) return; // superseded
      if (bytes == null) return;
      _pausedByLifecycle = false;
      await _music.play(BytesSource(bytes));
      if (gen != _musicGen || _disposed) {
        await _music.stop();
        return;
      }
      _currentTrack = track;
      await applyVolumes();
    } catch (_) {}
  }

  Future<void> menuMusic() => _startTrack('menu', 'music_menu.wav');
  Future<void> gameMusic() => _startTrack('game', 'music_game.wav');

  Future<void> stopMusic() async {
    _musicGen++;
    _currentTrack = null;
    _pausedByLifecycle = false;
    try {
      await _music.stop();
    } catch (_) {}
  }

  Future<void> duckMusic() async {
    try {
      await _music.setVolume(SettingsStore.I.musicVolume * 0.25);
    } catch (_) {}
  }

  Future<void> unduckMusic() => applyVolumes();

  /// App-lifecycle pause: freeze playback in place (resumable).
  Future<void> onLifecyclePause() async {
    try {
      _pausedByLifecycle = true;
      await _music.pause();
      await _sfx.stop();
    } catch (_) {}
  }

  /// App-lifecycle resume: continue exactly where playback left off.
  Future<void> onLifecycleResume() async {
    try {
      if (_disposed) return;
      if (_pausedByLifecycle && SettingsStore.I.musicOn && _currentTrack != null) {
        _pausedByLifecycle = false;
        await _music.resume();
      } else {
        _pausedByLifecycle = false;
      }
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _musicGen++;
    SettingsStore.I.removeListener(_onSettingsChanged);
    _sfx.dispose();
    _music.dispose();
    _cache.clear();
  }
}
