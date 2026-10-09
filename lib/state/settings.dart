/// Persistent settings: audio toggles + volume, difficulty, who starts.
/// Backed by shared_preferences; exposed as a ChangeNotifier.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/ai.dart';
import '../theme/morris_themes.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore I = SettingsStore._();

  static const _kMusic = 'nmm_music_on';
  static const _kSfx = 'nmm_sfx_on';
  static const _kMusicVol = 'nmm_music_vol';
  static const _kSfxVol = 'nmm_sfx_vol';
  static const _kDiff = 'nmm_difficulty';
  static const _kHumanFirst = 'nmm_human_first';
  static const _kName0 = 'nmm_name_0';
  static const _kName1 = 'nmm_name_1';
  static const _kTheme = 'nmm_theme';
  static const _kPiece = 'nmm_piece';
  static const _kAccent = 'nmm_accent';
  static const _kCustomColors = 'nmm_custom_colors';
  static const _kPro = 'nmm_pro_unlocked';

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.8;
  double sfxVolume = 0.8;
  Difficulty difficulty = Difficulty.medium;
  bool humanFirst = true;

  // Renameable player slots, persisted (MASTER_RULES gameplay quality bar).
  String name0 = 'Bronze';
  String name1 = 'Bone';

  // Customization: theme, piece style, board accent + custom creator colors.
  String themeId = 'lapidary';
  String pieceStyleId = 'classic';
  String accentId = 'verdigris';
  List<int> customColors = const [0xFFC2A87D, 0xFF8C6239, 0xFFD0C5B7, 0xFF4A7C6D];

  // Pro unlock (one-time purchase; also settable by IAP service).
  bool proUnlocked = false;

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
    name0 = p.getString(_kName0) ?? 'Bronze';
    name1 = p.getString(_kName1) ?? 'Bone';
    themeId = p.getString(_kTheme) ?? 'lapidary';
    pieceStyleId = p.getString(_kPiece) ?? 'classic';
    accentId = p.getString(_kAccent) ?? 'verdigris';
    final cc = p.getString(_kCustomColors);
    if (cc != null) {
      final parts = cc.split(',').map(int.tryParse).toList();
      if (parts.length == 4 && parts.every((e) => e != null)) {
        customColors = parts.cast<int>();
      }
    }
    proUnlocked = p.getBool(_kPro) ?? false;
    _ready = true;
    notifyListeners();
  }

  String playerName(int seat) => seat == 0 ? name0 : name1;

  MorrisTheme get customTheme => MorrisTheme.custom(
        sandstone: Color(customColors[0]),
        bronze: Color(customColors[1]),
        bone: Color(customColors[2]),
        accent: Color(customColors[3]),
      );

  MorrisTheme get activeTheme =>
      themeById(themeId, custom: themeId == 'custom' ? customTheme : null);

  /// A pro-gated choice the free tier cannot use (locked behind the Pro
  /// screen). Free keeps 4 themes + 3 piece styles + 2 accents.
  bool choiceUnlocked({required bool proOnly}) => proUnlocked || !proOnly;

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

  Future<void> setPlayerName(int seat, String name) async {
    final clean = name.trim().isEmpty ? (seat == 0 ? 'Bronze' : 'Bone') : name.trim();
    if (seat == 0) {
      name0 = clean;
      (await SharedPreferences.getInstance()).setString(_kName0, clean);
    } else {
      name1 = clean;
      (await SharedPreferences.getInstance()).setString(_kName1, clean);
    }
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    themeId = id;
    (await SharedPreferences.getInstance()).setString(_kTheme, id);
    notifyListeners();
  }

  Future<void> setPieceStyle(String id) async {
    pieceStyleId = id;
    (await SharedPreferences.getInstance()).setString(_kPiece, id);
    notifyListeners();
  }

  Future<void> setAccent(String id) async {
    accentId = id;
    (await SharedPreferences.getInstance()).setString(_kAccent, id);
    notifyListeners();
  }

  Future<void> setCustomColors(List<int> colors) async {
    customColors = List<int>.from(colors);
    (await SharedPreferences.getInstance())
        .setString(_kCustomColors, colors.join(','));
    notifyListeners();
  }

  Future<void> setProUnlocked(bool v) async {
    proUnlocked = v;
    (await SharedPreferences.getInstance()).setBool(_kPro, v);
    notifyListeners();
  }
}
