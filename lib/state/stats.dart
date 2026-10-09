/// Per-game results and aggregate statistics, persisted via
/// shared_preferences. Star ratings apply to Player-vs-AI wins (RULES.md §8).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../engine/ai.dart';

class GameResult {
  final String outcome; // 'win' | 'loss' | 'draw' (from the human's view, or P0 in 2P)
  final int millsFormed;
  final int captures;
  final int plies;
  final int durationSec;
  final int stars; // 0-3, PvAI wins only
  final Difficulty difficulty;
  final bool vsAi;

  const GameResult({
    required this.outcome,
    required this.millsFormed,
    required this.captures,
    required this.plies,
    required this.durationSec,
    required this.stars,
    required this.difficulty,
    required this.vsAi,
  });

  Map<String, Object?> toJson() => {
        'outcome': outcome,
        'millsFormed': millsFormed,
        'captures': captures,
        'plies': plies,
        'durationSec': durationSec,
        'stars': stars,
        'difficulty': difficulty.index,
        'vsAi': vsAi,
      };

  factory GameResult.fromJson(Map<String, Object?> j) => GameResult(
        outcome: j['outcome'] as String,
        millsFormed: (j['millsFormed'] as int?) ?? 0,
        captures: (j['captures'] as int?) ?? 0,
        plies: (j['plies'] as int?) ?? 0,
        durationSec: (j['durationSec'] as int?) ?? 0,
        stars: (j['stars'] as int?) ?? 0,
        difficulty: Difficulty.values[(j['difficulty'] as int?) ?? 1],
        vsAi: (j['vsAi'] as bool?) ?? true,
      );
}

class StatsStore {
  StatsStore._();
  static final StatsStore I = StatsStore._();

  static const _kStats = 'nmm_stats_v1';

  int wins = 0;
  int losses = 0;
  int draws = 0;
  int totalMills = 0;
  int totalCaptures = 0;
  final Map<Difficulty, int> bestStars = {
    Difficulty.easy: 0,
    Difficulty.medium: 0,
    Difficulty.hard: 0,
  };

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kStats);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      wins = (j['wins'] as int?) ?? 0;
      losses = (j['losses'] as int?) ?? 0;
      draws = (j['draws'] as int?) ?? 0;
      totalMills = (j['totalMills'] as int?) ?? 0;
      totalCaptures = (j['totalCaptures'] as int?) ?? 0;
      final stars = j['bestStars'] as Map?;
      if (stars != null) {
        for (final d in Difficulty.values) {
          bestStars[d] = (stars['${d.index}'] as int?) ?? 0;
        }
      }
    } catch (_) {
      // Corrupt stats: start fresh rather than crash.
    }
  }

  Future<void> record(GameResult r) async {
    switch (r.outcome) {
      case 'win':
        wins++;
      case 'loss':
        losses++;
      default:
        draws++;
    }
    totalMills += r.millsFormed;
    totalCaptures += r.captures;
    if (r.vsAi && r.outcome == 'win' && r.stars > bestStars[r.difficulty]!) {
      bestStars[r.difficulty] = r.stars;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kStats,
        jsonEncode({
          'wins': wins,
          'losses': losses,
          'draws': draws,
          'totalMills': totalMills,
          'totalCaptures': totalCaptures,
          'bestStars': {
            for (final d in Difficulty.values) '${d.index}': bestStars[d]
          },
        }));
  }

  Future<void> reset() async {
    wins = 0;
    losses = 0;
    draws = 0;
    totalMills = 0;
    totalCaptures = 0;
    for (final d in Difficulty.values) {
      bestStars[d] = 0;
    }
    final p = await SharedPreferences.getInstance();
    await p.remove(_kStats);
  }

  int get gamesPlayed => wins + losses + draws;
}
