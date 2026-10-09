/// Pure, deterministic Nine Men's Morris rules engine.
///
/// Board: `List<int>` of 24 — -1 empty, 0 player one (dark bronze),
/// 1 player two (pale bone). Reserves: `List<int>` of 2 (men left to place).
/// Implements RULES.md faithfully: placement / movement / flying, mills,
/// capture protection, win by reduction or blockade, repetition and
/// no-progress draws, undo-safe snapshots.
library;

import 'morris.dart';

/// Immutable snapshot of the full game state. Used for undo and persistence.
class MorrisSnapshot {
  final List<int> board;
  final List<int> reserve;
  final int turn;
  final int plies;
  final int pliesNoProgress;
  final List<String> positionHistory;
  final List<int> millsFormedBy; // player index per mill-forming ply
  final List<int> capturesBy; // player index per capture ply

  MorrisSnapshot({
    required this.board,
    required this.reserve,
    required this.turn,
    required this.plies,
    required this.pliesNoProgress,
    required this.positionHistory,
    required this.millsFormedBy,
    required this.capturesBy,
  });

  factory MorrisSnapshot.initial() => MorrisSnapshot(
        board: List<int>.filled(24, -1),
        reserve: const [9, 9],
        turn: 0,
        plies: 0,
        pliesNoProgress: 0,
        positionHistory: [],
        millsFormedBy: [],
        capturesBy: [],
      );

  MorrisSnapshot copy() => MorrisSnapshot(
        board: List<int>.from(board),
        reserve: List<int>.from(reserve),
        turn: turn,
        plies: plies,
        pliesNoProgress: pliesNoProgress,
        positionHistory: List<String>.from(positionHistory),
        millsFormedBy: List<int>.from(millsFormedBy),
        capturesBy: List<int>.from(capturesBy),
      );

  Map<String, Object?> toJson() => {
        'board': board,
        'reserve': reserve,
        'turn': turn,
        'plies': plies,
        'pliesNoProgress': pliesNoProgress,
        'positionHistory': positionHistory,
        'millsFormedBy': millsFormedBy,
        'capturesBy': capturesBy,
      };

  factory MorrisSnapshot.fromJson(Map<String, Object?> json) => MorrisSnapshot(
        board: (json['board'] as List).map((e) => e as int).toList(),
        reserve: (json['reserve'] as List).map((e) => e as int).toList(),
        turn: json['turn'] as int,
        plies: (json['plies'] as int?) ?? 0,
        pliesNoProgress: (json['pliesNoProgress'] as int?) ?? 0,
        positionHistory:
            (json['positionHistory'] as List?)?.map((e) => e as String).toList() ??
                const [],
        millsFormedBy:
            (json['millsFormedBy'] as List?)?.map((e) => e as int).toList() ??
                const [],
        capturesBy:
            (json['capturesBy'] as List?)?.map((e) => e as int).toList() ??
                const [],
      );
}

class MorrisEngine {
  MorrisEngine._();

  static int pieceCount(List<int> board, int p) {
    var n = 0;
    for (final v in board) {
      if (v == p) n++;
    }
    return n;
  }

  /// Indices into [MorrisBoard.mills] that player [p] currently holds closed.
  static Set<int> millsOn(List<int> board, int p) {
    final s = <int>{};
    for (var i = 0; i < MorrisBoard.mills.length; i++) {
      final m = MorrisBoard.mills[i];
      if (board[m[0]] == p && board[m[1]] == p && board[m[2]] == p) {
        s.add(i);
      }
    }
    return s;
  }

  static bool inPlacement(List<int> reserve, int p) => reserve[p] > 0;

  static bool placementDone(List<int> reserve) =>
      reserve[0] == 0 && reserve[1] == 0;

  /// Flying privilege: exactly 3 men and no reserves left.
  static bool isFlying(List<int> board, List<int> reserve, int p) =>
      reserve[p] == 0 && pieceCount(board, p) == 3;

  /// All legal moves for [p]: [from, to] pairs; from == -1 means placement.
  static List<List<int>> legalMoves(
      List<int> board, List<int> reserve, int p) {
    final ms = <List<int>>[];
    if (reserve[p] > 0) {
      for (var i = 0; i < 24; i++) {
        if (board[i] == -1) ms.add([-1, i]);
      }
      return ms;
    }
    final fly = isFlying(board, reserve, p);
    for (var f = 0; f < 24; f++) {
      if (board[f] != p) continue;
      for (var t = 0; t < 24; t++) {
        if (board[t] != -1) continue;
        if (fly || MorrisBoard.adj[f].contains(t)) ms.add([f, t]);
      }
    }
    return ms;
  }

  /// Legal destinations from point [from] for player [p] (movement phase).
  static List<int> destinationsFrom(
      List<int> board, List<int> reserve, int p, int from) {
    if (board[from] != p || reserve[p] > 0) return const [];
    if (isFlying(board, reserve, p)) {
      return [for (var i = 0; i < 24; i++) if (board[i] == -1) i];
    }
    return MorrisBoard.adj[from].where((t) => board[t] == -1).toList();
  }

  /// Opponent men [p] may capture: non-mill men first; if the foe holds only
  /// mills, any foe man may be taken (RULES.md §6 / §12.1).
  static List<int> captureTargets(List<int> board, int p) {
    final foe = 1 - p;
    final inMill = <int>{};
    for (final mi in millsOn(board, foe)) {
      inMill.addAll(MorrisBoard.mills[mi]);
    }
    final all = [for (var i = 0; i < 24; i++) if (board[i] == foe) i];
    final free = all.where((i) => !inMill.contains(i)).toList();
    return free.isEmpty ? all : free;
  }

  /// Canonical position key for repetition tracking: men on points + side.
  static String positionKey(List<int> board, int turn) {
    final sb = StringBuffer();
    for (final v in board) {
      sb.write(v == -1 ? '.' : v.toString());
    }
    sb.write(turn);
    return sb.toString();
  }

  /// Result of applying a full ply (move + mandatory capture, if any).
  /// Returns the resulting snapshot and outcome info.
  static PlyResult applyPly(MorrisSnapshot s, int from, int to, int capture) {
    final board = List<int>.from(s.board);
    final reserve = List<int>.from(s.reserve);
    final p = s.turn;
    final before = millsOn(board, p);
    if (from != -1) board[from] = -1;
    board[to] = p;
    if (from == -1) reserve[p]--;

    final after = millsOn(board, p);
    final fresh = after.difference(before);
    final formedMill = fresh.isNotEmpty;

    int capturedAt = -1;
    if (formedMill) {
      final targets = captureTargets(board, p);
      if (targets.isEmpty) {
        // Unreachable by legal play (a mill implies the foe holds a man),
        // but never corrupt state: treat as no capture rather than crash.
        return _completePly(
            s,
            board,
            reserve,
            p,
            1 - p,
            formedMill,
            -1,
            List<String>.from(s.positionHistory),
            s.pliesNoProgress);
      }
      if (!targets.contains(capture)) {
        throw StateError(
            'MorrisEngine.applyPly: illegal capture target $capture for player $p '
            '(legal: $targets). Mill was newly formed; the caller must pick a '
            'legal target from captureTargets().');
      }
      capturedAt = capture;
      board[capturedAt] = -1;
    }

    final foe = 1 - p;

    // Draw bookkeeping (only meaningful in the movement phase).
    var noProgress = s.pliesNoProgress;
    if (placementDone(reserve)) {
      noProgress = (formedMill || capturedAt != -1) ? 0 : noProgress + 1;
    }
    final history = List<String>.from(s.positionHistory);

    return _completePly(s, board, reserve, p, foe, formedMill, capturedAt,
        history, noProgress);
  }

  /// Shared tail of [applyPly]: win/draw checks, draw bookkeeping, snapshot.
  /// `history` and `noProgress` are the already-updated movement-phase
  /// bookkeeping (no-op during placement).
  static PlyResult _completePly(
      MorrisSnapshot s,
      List<int> board,
      List<int> reserve,
      int p,
      int foe,
      bool formedMill,
      int capturedAt,
      List<String> history,
      int noProgress) {
    final foeCount = pieceCount(board, foe);
    final foeMoves =
        placementDone(reserve) ? legalMoves(board, reserve, foe) : null;

    String? winner; // '0' | '1' | 'draw' | null
    String? endReason;
    // RULES.md §7 check order: (a) opponent at 2 men → win; (b) no legal move.
    // Reduction can only result from a capture, which implies a mill.
    if (formedMill && placementDone(reserve) && foeCount <= 2) {
      winner = '$p';
      endReason = 'reduction';
    } else if (foeMoves != null && foeMoves.isEmpty) {
      winner = '$p';
      endReason = 'blocked';
    }

    String? drawBy;
    if (winner == null && placementDone(reserve)) {
      final key = positionKey(board, foe);
      history.add(key);
      final repeats = history.where((k) => k == key).length;
      if (repeats >= 3) {
        winner = 'draw';
        drawBy = 'repetition';
      } else if (noProgress >= 50) {
        winner = 'draw';
        drawBy = 'no-progress';
      }
    }

    final millsBy = List<int>.from(s.millsFormedBy);
    if (formedMill) millsBy.add(p);
    final capsBy = List<int>.from(s.capturesBy);
    if (capturedAt != -1) capsBy.add(p);

    final next = MorrisSnapshot(
      board: board,
      reserve: reserve,
      turn: winner == null ? foe : p,
      plies: s.plies + 1,
      pliesNoProgress: noProgress,
      positionHistory: history,
      millsFormedBy: millsBy,
      capturesBy: capsBy,
    );
    return PlyResult(
      snapshot: next,
      formedMill: formedMill,
      capturedAt: capturedAt,
      winner: winner,
      endReason: endReason ?? drawBy,
    );
  }

}

/// Outcome of one completed ply.
class PlyResult {
  final MorrisSnapshot snapshot;
  final bool formedMill;
  final int capturedAt; // -1 when no capture
  final String? winner; // '0', '1', 'draw', or null while the game continues
  final String? endReason; // 'reduction' | 'blocked' | 'repetition' | 'no-progress'

  const PlyResult({
    required this.snapshot,
    required this.formedMill,
    required this.capturedAt,
    required this.winner,
    required this.endReason,
  });
}
