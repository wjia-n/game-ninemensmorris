/// Persistent settings: audio toggles + volume, difficulty, who starts.
/// Backed by shared_preferences; exposed as a ChangeNotifier.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/ai.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore I = SettingsStore._();

  static const _kMusic = 'nmm_music_on';
  static const _kSfx = 'nmm_sfx_on';
  static const _kMusicVol = 'nmm_music_vol';
  static const _kSfxVol = 'nmm_sfx_vol';
  static const _kDiff = 'nmm_difficulty';
  static const _kHumanFirst = 'nmm_human_first';

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.8;
  double sfxVolume = 0.8;
  Difficulty difficulty = Difficulty.medium;
  bool humanFirst = true;

  bool _ready = false;
  bool get ready => _ready;

  Future<void> init() async {
    if (_ready) return;
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    musicVolume = (p.getDouble(_kMusicVol) ?? 0.8).clamp(0.0, 1.0);
    sfxVolume = (p.getDouble(_kSfxVol) ?? 0.8).clamp(0.0, 1.0);
    difficulty = Difficulty.values[p.getInt(_kDiff) ?? 1];
    humanFirst = p.getBool(_kHumanFirst) ?? true;
    _ready = true;
    notifyListeners();
  }

  Future<void> setMusic(bool on) async {
    musicOn = on;
    (await SharedPreferences.getInstance()).setBool(_kMusic, on);
    notifyListeners();
  }

  Future<void> setSfx(bool on) async {
    sfxOn = on;
    (await SharedPreferences.getInstance()).setBool(_kSfx, on);
    notifyListeners();
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0.0, 1.0);
    (await SharedPreferences.getInstance()).setDouble(_kMusicVol, musicVolume);
    notifyListeners();
  }

  Future<void> setSfxVolume(double v) async {
    sfxVolume = v.clamp(0.0, 1.0);
    (await SharedPreferences.getInstance()).setDouble(_kSfxVol, sfxVolume);
    notifyListeners();
  }

  Future<void> setDifficulty(Difficulty d) async {
    difficulty = d;
    (await SharedPreferences.getInstance()).setInt(_kDiff, d.index);
    notifyListeners();
  }

  Future<void> setHumanFirst(bool v) async {
    humanFirst = v;
    (await SharedPreferences.getInstance()).setBool(_kHumanFirst, v);
    notifyListeners();
  }
}
