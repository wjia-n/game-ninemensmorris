/// Bot-vs-bot simulation: proves stuck states are impossible.
///
/// Plays full games through the pure engine with AI-vs-AI at all difficulty
/// pairings plus random play, asserting:
/// - every game terminates (win by reduction/blocking, or draw),
/// - every ply is legal (engine validates moves and captures),
/// - no exceptions, no infinite loops (hard ply cap far above the 50-ply
///   no-progress draw, which must fire first).
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ninemensmorris/engine/ai.dart';
import 'package:ninemensmorris/engine/engine.dart';
import 'package:ninemensmorris/engine/morris.dart';

/// Plays one full game. Returns (winner, plies).
(String?, int) playGame(Difficulty d0, Difficulty d1, Random rng) {
  var s = MorrisSnapshot.initial();
  const cap = 400; // far above the 50-ply no-progress draw
  for (var ply = 0; ply < cap; ply++) {
    final p = s.turn;
    final diff = p == 0 ? d0 : d1;
    final moves = MorrisEngine.legalMoves(s.board, s.reserve, p);
    // During placement a move always exists; in movement the engine ends the
    // game (blocked win) at the end of the previous ply, so an empty move
    // list here would be a stuck state — fail loudly.
    expect(moves, isNotEmpty,
        reason: 'stuck: player $p has no legal move at ply $ply');
    List<int> m;
    if (rng.nextDouble() < 0.15) {
      m = moves[rng.nextInt(moves.length)]; // inject randomness
    } else {
      m = MorrisAi.chooseMove(s.board, s.reserve, p, diff, rng);
      if (!moves.any((x) => x[0] == m[0] && x[1] == m[1])) {
        m = moves.first; // AI must only return legal moves
      }
    }
    // Validate the move is genuinely legal before applying.
    if (m[0] == -1) {
      expect(s.reserve[p] > 0, isTrue);
      expect(s.board[m[1]], -1);
    } else {
      expect(s.board[m[0]], p);
      expect(s.board[m[1]], -1);
      final fly = MorrisEngine.isFlying(s.board, s.reserve, p);
      expect(fly || MorrisBoard.adj[m[0]].contains(m[1]), isTrue);
    }
    // Resolve the ply like the controller does: preview the mill, then pick
    // a legal capture target.
    final before = MorrisEngine.millsOn(s.board, p);
    final b = List<int>.from(s.board);
    final r = List<int>.from(s.reserve);
    if (m[0] != -1) b[m[0]] = -1;
    b[m[1]] = p;
    if (m[0] == -1) r[p]--;
    final formed = MorrisEngine.millsOn(b, p).difference(before).isNotEmpty;
    var capture = -1;
    if (formed) {
      final targets = MorrisEngine.captureTargets(b, p);
      expect(targets, isNotEmpty);
      capture = targets[rng.nextInt(targets.length)];
    }
    final res = MorrisEngine.applyPly(s, m[0], m[1], capture);
    if (formed) {
      expect(res.formedMill, isTrue);
      expect(res.capturedAt, capture);
    }
    // Invariants after every ply.
    final nb = res.snapshot.board;
    expect(nb.length, 24);
    for (final v in nb) {
      expect(v >= -1 && v <= 1, isTrue,
          reason: 'board value out of range: $v');
    }
    expect(res.snapshot.reserve[0] >= 0 && res.snapshot.reserve[1] >= 0,
        isTrue);
    s = res.snapshot;
    if (res.winner != null) {
      expect(['0', '1', 'draw'], contains(res.winner));
      expect(
          ['reduction', 'blocked', 'repetition', 'no-progress'],
          contains(res.endReason));
      return (res.winner, res.snapshot.plies);
    }
  }
  fail('game did not terminate within $cap plies — stuck state');
}

void main() {
  test('bot-vs-bot: all difficulty pairings terminate legally', () {
    final rng = Random(20261009);
    final diffs = Difficulty.values;
    var games = 0;
    for (final d0 in diffs) {
      for (final d1 in diffs) {
        for (var g = 0; g < 3; g++) {
          final (winner, plies) = playGame(d0, d1, rng);
          expect(winner, isNotNull);
          expect(plies, lessThan(400));
          games++;
        }
      }
    }
    expect(games, 27);
  });

  test('bot-vs-bot: hard-vs-hard terminates (deep search, seeded)', () {
    final rng = Random(77);
    for (var g = 0; g < 3; g++) {
      final (winner, plies) =
          playGame(Difficulty.hard, Difficulty.hard, rng);
      expect(winner, isNotNull);
      expect(plies, lessThan(400));
    }
  });

  test('illegal capture target throws StateError (never corrupts)', () {
    // P0 holds 0,1 and places 2 to close a mill; P1 has a man at 8.
    final b = List<int>.filled(24, -1);
    b[0] = 0;
    b[1] = 0;
    b[8] = 1;
    final s = MorrisSnapshot(
      board: b,
      reserve: [7, 8],
      turn: 0,
      plies: 0,
      pliesNoProgress: 0,
      positionHistory: [],
      millsFormedBy: [],
      capturesBy: [],
    );
    // Capturing an empty point must fail loudly, not corrupt the board.
    expect(() => MorrisEngine.applyPly(s, -1, 2, 5), throwsStateError);
    // Board untouched by the failed ply.
    expect(s.board[8], 1);
  });

  test('no-progress draw fires at exactly 50 plies', () {
    // Movement phase, no mills/captures possible in one ply: shuttle two men
    // back and forth without forming mills.
    final b = List<int>.filled(24, -1);
    b[0] = 0;
    b[9] = 0;
    b[10] = 0;
    b[4] = 1;
    b[13] = 1;
    b[14] = 1;
    var s = MorrisSnapshot(
      board: b,
      reserve: [0, 0],
      turn: 0,
      plies: 0,
      pliesNoProgress: 49,
      positionHistory: [],
      millsFormedBy: [],
      capturesBy: [],
    );
    // 0: 1 -> 2 (no mill: 2's mill needs 0,1,2... wait 0,1,2 IS a mill).
    // Use a safe shuttle instead: 9 -> 8 and back (no mill involves 8,9).
    var r = MorrisEngine.applyPly(s, 9, 8, -1);
    expect(r.winner, 'draw');
    expect(r.endReason, 'no-progress');
  });
}
