/// Engine conformance tests against RULES.md §13 test cases.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ninemensmorris/engine/engine.dart';
import 'package:ninemensmorris/engine/morris.dart';

MorrisSnapshot snapWith({
  List<int>? board,
  List<int>? reserve,
  int turn = 0,
  int plies = 0,
  int pliesNoProgress = 0,
  List<String>? history,
}) {
  return MorrisSnapshot(
    board: board ?? List<int>.filled(24, -1),
    reserve: reserve ?? [0, 0],
    turn: turn,
    plies: plies,
    pliesNoProgress: pliesNoProgress,
    positionHistory: history ?? [],
    millsFormedBy: [],
    capturesBy: [],
  );
}

void main() {
  test('T1: placement on empty point succeeds, reserve drops, turn passes',
      () {
    final s = snapWith(reserve: [9, 9]);
    final r = MorrisEngine.applyPly(s, -1, 0, -1);
    expect(r.snapshot.board[0], 0);
    expect(r.snapshot.reserve[0], 8);
    expect(r.snapshot.turn, 1);
    expect(r.winner, isNull);
  });

  test('T3: mill formed in placement grants exactly one capture', () {
    // P1 holds O1(0), O2(1); P2 has a man at 8 and a mill at 4-5-6.
    final b = List<int>.filled(24, -1);
    b[0] = 0;
    b[1] = 0;
    b[8] = 1;
    b[4] = 1;
    b[5] = 1;
    b[6] = 1;
    final s = snapWith(board: b, reserve: [7, 8]);
    final r = MorrisEngine.applyPly(s, -1, 2, 8); // O3 completes mill
    expect(r.formedMill, isTrue);
    expect(r.snapshot.board[8], -1); // captured
    expect(r.snapshot.board[4], 1); // mill-protected man kept
    expect(r.snapshot.turn, 1);
  });

  test('T4: mill-piece protection — must take the non-mill man', () {
    final targets = MorrisEngine.captureTargets(
        snapWith(board: (() {
          final b = List<int>.filled(24, -1);
          b[0] = 0;
          b[1] = 0;
          b[2] = 0; // P0 mill
          b[8] = 1;
          b[9] = 1;
          b[10] = 1; // P1 mill
          b[14] = 1; // lone P1 man
          return b;
        })())
            .board,
        0);
    expect(targets, [14]);
  });

  test('T5: all-in-mills — any foe man may be taken', () {
    final b = List<int>.filled(24, -1);
    b[0] = 0;
    b[1] = 0;
    b[2] = 0;
    b[8] = 1;
    b[9] = 1;
    b[10] = 1;
    final targets = MorrisEngine.captureTargets(b, 0);
    expect(targets.toSet(), {8, 9, 10});
  });

  test('T6: reopened mill grants a capture again', () {
    // P0 mill at 0-1-2; move 0->7 (opens), then 7->0 (recloses).
    final b = List<int>.filled(24, -1);
    b[1] = 0;
    b[2] = 0;
    b[7] = 0;
    b[8] = 1;
    b[10] = 1;
    final s = snapWith(board: b, reserve: [0, 0], turn: 0);
    final r = MorrisEngine.applyPly(s, 7, 0, 8);
    expect(r.formedMill, isTrue);
    expect(r.capturedAt, 8);
  });

  test('T7: movement adjacency rules', () {
    // P0 man at M2(9); M3(10) and O2(1) occupied by foe; I2(17) empty.
    final b = List<int>.filled(24, -1);
    b[9] = 0;
    b[10] = 1;
    b[1] = 1;
    final dests = MorrisEngine.destinationsFrom(b, [0, 0], 0, 9);
    expect(dests.contains(17), isTrue); // radial I2, now reachable
    expect(dests.contains(8), isTrue); // M1
    expect(dests.contains(10), isFalse); // occupied
    expect(dests.contains(1), isFalse); // occupied
  });

  test('T8: flying — 3 men may jump anywhere; 5 men may not', () {
    final b3 = List<int>.filled(24, -1);
    b3[0] = 0;
    b3[1] = 0;
    b3[2] = 0;
    b3[8] = 1;
    final flyDests = MorrisEngine.destinationsFrom(b3, [0, 0], 0, 0);
    expect(flyDests.length, 24 - 4);

    final b5 = List<int>.filled(24, -1);
    for (final i in [0, 1, 2, 3, 4]) {
      b5[i] = 0;
    }
    b5[8] = 1;
    final walkDests = MorrisEngine.destinationsFrom(b5, [0, 0], 0, 0);
    expect(walkDests.toSet(), {7}); // 1 occupied; only the free neighbor
  });

  test('T9: win by reduction \u2014 foe drops to 2 (movement phase)', () {
    final b = List<int>.filled(24, -1);
    b[1] = 0;
    b[2] = 0;
    b[7] = 0;
    b[8] = 1;
    b[9] = 1;
    b[10] = 1;
    final s = snapWith(board: b, reserve: [0, 0], turn: 0);
    final r = MorrisEngine.applyPly(s, 7, 0, 8); // 7->0 closes mill 0-1-2
    expect(r.formedMill, isTrue);
    expect(r.winner, '0');
    expect(r.endReason, 'reduction');
    expect(MorrisEngine.pieceCount(r.snapshot.board, 1), 2);
  });

  test('T10: win by blocking \u2014 foe has no legal move', () {
    // P1 men at 9, 12, 16, 20; every neighboring point held by P0.
    // P0's man at 0 slides 0->7 as the quiet triggering move.
    final b = List<int>.filled(24, -1);
    b[9] = 1;
    b[12] = 1;
    b[16] = 1;
    b[20] = 1;
    for (final i in [0, 1, 8, 10, 11, 13, 17, 19, 21, 23]) {
      b[i] = 0;
    }
    final s = snapWith(board: b, reserve: [0, 0], turn: 0);
    final r = MorrisEngine.applyPly(s, 0, 7, -1);
    expect(r.formedMill, isFalse);
    expect(r.winner, '0');
    expect(r.endReason, 'blocked');
  });

  test('T12: repetition — same position 3 times is a draw', () {
    // Board X reached with P1 to move; the key already occurred twice.
    final x = List<int>.filled(24, -1);
    x[0] = 0;
    x[2] = 0;
    x[8] = 1;
    x[10] = 1;
    final k = MorrisEngine.positionKey(x, 1);
    // xPrime: X with P0's man displaced 0 -> 7; P0 moves it back.
    final xPrime = List<int>.from(x)
      ..[0] = -1
      ..[7] = 0;
    final s = snapWith(
        board: xPrime, reserve: [0, 0], turn: 0, history: [k, k]);
    final r = MorrisEngine.applyPly(s, 7, 0, -1);
    expect(r.snapshot.board, x);
    expect(r.winner, 'draw');
    expect(r.endReason, 'repetition');
  });

  test('T13: no-progress — 50 plies without mill/capture is a draw', () {
    final b = List<int>.filled(24, -1);
    b[0] = 0;
    b[8] = 1;
    final s = snapWith(
        board: b, reserve: [0, 0], turn: 0, pliesNoProgress: 49);
    final r = MorrisEngine.applyPly(s, 0, 1, -1);
    expect(r.winner, 'draw');
    expect(r.endReason, 'no-progress');
  });

  test('T14: placement completes after 18 plies -> movement phase', () {
    final b = List<int>.filled(24, -1);
    // 17 men placed (9 P0 incl. 0,1 ; 8 P1), one reserve left for P1.
    for (final i in [0, 1, 3, 5, 8, 10, 12, 16, 18]) {
      b[i] = 0;
    }
    for (final i in [2, 4, 6, 9, 11, 13, 17, 19]) {
      b[i] = 1;
    }
    final s = snapWith(board: b, reserve: [0, 1], turn: 1, plies: 17);
    final r = MorrisEngine.applyPly(s, -1, 7, -1);
    expect(r.snapshot.reserve, [0, 0]);
    expect(r.snapshot.plies, 18);
    expect(MorrisEngine.placementDone(r.snapshot.reserve), isTrue);
    expect(r.winner, isNull); // game continues into movement
  });

  test('mills: the 16 known mills are detected', () {
    for (final mill in MorrisBoard.mills) {
      final b = List<int>.filled(24, -1);
      for (final i in mill) {
        b[i] = 0;
      }
      expect(MorrisEngine.millsOn(b, 0), {MorrisBoard.mills.indexOf(mill)});
    }
  });

  test('adjacency is symmetric and radials span all three squares', () {
    for (var i = 0; i < 24; i++) {
      for (final j in MorrisBoard.adj[i]) {
        expect(MorrisBoard.adj[j].contains(i), isTrue,
            reason: '$j should list $i');
      }
    }
    // The four radial lines: outer-mid-inner midpoints fully linked.
    for (final radial in MorrisBoard.radials) {
      expect(MorrisBoard.adj[radial[0]].contains(radial[1]), isTrue);
      expect(MorrisBoard.adj[radial[1]].contains(radial[0]), isTrue);
      expect(MorrisBoard.adj[radial[1]].contains(radial[2]), isTrue);
      expect(MorrisBoard.adj[radial[2]].contains(radial[1]), isTrue);
    }
  });
}
