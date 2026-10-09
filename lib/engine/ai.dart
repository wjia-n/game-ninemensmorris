/// Bot opponent for Nine Men's Morris — heuristic + minimax per RULES.md §11.
///
/// Evaluation (from player [p]'s perspective):
/// - Material: +100 per man advantage (board + reserves).
/// - Mobility: +4 per legal-move advantage.
/// - Open mills: +25 per own open mill, -25 per opponent open mill.
/// - Closed mills: +10 per closed mill of our own, -10 opponent's.
/// - Positional: +3 per man on high-connectivity (hot) points.
/// - Phase awareness: placement bonuses for inner-square and corner points.
///
/// Difficulties: easy = 1-ply + 30% random; medium = depth-2 minimax;
/// hard = depth-4 minimax with move ordering (mill-closings/captures first).
library;

import 'dart:math';

import 'engine.dart';
import 'morris.dart';

enum Difficulty { easy, medium, hard }

/// Greedy "ply" used inside search: move + the best immediate capture for [p].
class _SimPly {
  final List<int> board;
  final List<int> reserve;
  final bool formedMill;
  const _SimPly(this.board, this.reserve, this.formedMill);
}

class MorrisAi {
  MorrisAi._();

  static List<int> chooseMove(List<int> board, List<int> reserve, int p,
      Difficulty diff, Random rng) {
    final moves = MorrisEngine.legalMoves(board, reserve, p);
    if (moves.isEmpty) return const [-1, -1];
    if (moves.length == 1) return moves.first;

    if (diff == Difficulty.easy) {
      if (rng.nextDouble() < 0.3) return moves[rng.nextInt(moves.length)];
      return _bestShallow(board, reserve, p, moves, rng);
    }
    final depth = diff == Difficulty.medium ? 2 : 4;
    final ordered = _orderMoves(board, reserve, p, moves);
    var best = ordered.first;
    var bestScore = -1e18;
    var alpha = -1e18;
    const beta = 1e18;
    final budget = _NodeBudget(120000);
    for (final m in ordered) {
      final sim = _simApply(board, reserve, p, m[0], m[1]);
      final score = -_search(sim.board, sim.reserve, 1 - p, depth - 1, -beta,
          -alpha, p, budget);
      if (!budget.ok) break;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
      if (score > alpha) alpha = score;
    }
    return best;
  }

  static int chooseCapture(
      List<int> board, int p, Difficulty diff, Random rng) {
    final targets = MorrisEngine.captureTargets(board, p);
    if (targets.length == 1) return targets.first;
    var best = targets.first;
    var bestScore = -1e18;
    for (final t in targets) {
      var score = rng.nextDouble() * (diff == Difficulty.easy ? 12 : 2);
      // Prefer removing men that threaten (or hold) open mills.
      for (final mill in MorrisBoard.mills) {
        if (!mill.contains(t)) continue;
        final foe = 1 - p;
        final others = mill.where((x) => x != t).toList();
        if (board[others[0]] == foe && board[others[1]] == foe) score += 40;
        if (board[others[0]] == foe || board[others[1]] == foe) score += 6;
      }
      if (MorrisBoard.hotPoints.contains(t)) score += 4;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }
    return best;
  }

  // --- search internals ------------------------------------------------------

  static List<int> _bestShallow(List<int> board, List<int> reserve, int p,
      List<List<int>> moves, Random rng) {
    var best = moves.first;
    var bestScore = -1e18;
    for (final m in moves) {
      final sim = _simApply(board, reserve, p, m[0], m[1]);
      var score = evaluate(sim.board, sim.reserve, p);
      if (sim.formedMill) score += 500;
      score += rng.nextDouble() * 8;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  /// Apply move + greedy best capture (no win/draw checks — search only).
  static _SimPly _simApply(
      List<int> board, List<int> reserve, int p, int from, int to) {
    final b = List<int>.from(board);
    final r = List<int>.from(reserve);
    final before = MorrisEngine.millsOn(b, p);
    if (from != -1) b[from] = -1;
    b[to] = p;
    if (from == -1) r[p]--;
    final after = MorrisEngine.millsOn(b, p);
    final formed = after.difference(before).isNotEmpty;
    if (formed) {
      b[_greedyCapture(b, r, p)] = -1;
    }
    return _SimPly(b, r, formed);
  }

  static int _greedyCapture(List<int> board, List<int> reserve, int p) {
    final targets = MorrisEngine.captureTargets(board, p);
    var best = targets.first;
    var bestScore = -1e18;
    for (final t in targets) {
      final b = List<int>.from(board)..[t] = -1;
      final score = evaluate(b, reserve, p);
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }
    return best;
  }

  static List<List<int>> _orderMoves(List<int> board, List<int> reserve, int p,
      List<List<int>> moves) {
    final scored = <({List<int> m, double s})>[];
    for (final m in moves) {
      final sim = _simApply(board, reserve, p, m[0], m[1]);
      var s = evaluate(sim.board, sim.reserve, p);
      if (sim.formedMill) s += 1000;
      if (MorrisBoard.hotPoints.contains(m[1])) s += 10;
      scored.add((m: m, s: s));
    }
    scored.sort((a, b) => b.s.compareTo(a.s));
    return scored.map((e) => e.m).toList();
  }

  static double _search(List<int> board, List<int> reserve, int toMove,
      int depth, double alpha, double beta, int maxP, _NodeBudget budget) {
    budget.tick();
    if (!budget.ok) return evaluate(board, reserve, maxP);

    // Terminal: toMove is reduced to 2 or blocked (movement phase).
    final foe = 1 - toMove;
    if (MorrisEngine.placementDone(reserve)) {
      if (MorrisEngine.pieceCount(board, toMove) <= 2) {
        return toMove == maxP ? -100000 : 100000;
      }
      final moves = MorrisEngine.legalMoves(board, reserve, toMove);
      if (moves.isEmpty) return toMove == maxP ? -100000 : 100000;
      if (depth <= 0) return evaluate(board, reserve, maxP);
      var best = -1e18;
      for (final m in moves) {
        final sim = _simApply(board, reserve, toMove, m[0], m[1]);
        final s = -_search(sim.board, sim.reserve, foe, depth - 1, -beta, -alpha,
            maxP, budget);
        if (s > best) best = s;
        if (best > alpha) alpha = best;
        if (alpha >= beta || !budget.ok) break;
      }
      return best;
    }
    // Placement phase: depth-limited only.
    if (depth <= 0) return evaluate(board, reserve, maxP);
    final moves = MorrisEngine.legalMoves(board, reserve, toMove);
    var best = -1e18;
    for (final m in moves) {
      final sim = _simApply(board, reserve, toMove, m[0], m[1]);
      final s = -_search(sim.board, sim.reserve, foe, depth - 1, -beta, -alpha,
          maxP, budget);
      if (s > best) best = s;
      if (best > alpha) alpha = best;
      if (alpha >= beta || !budget.ok) break;
    }
    return best;
  }

  /// Heuristic evaluation from [p]'s perspective (RULES.md §11).
  static double evaluate(List<int> board, List<int> reserve, int p) {
    final foe = 1 - p;
    final myMen = MorrisEngine.pieceCount(board, p) + reserve[p];
    final foeMen = MorrisEngine.pieceCount(board, foe) + reserve[foe];
    var score = (myMen - foeMen) * 100.0;

    final myMoves = MorrisEngine.legalMoves(board, reserve, p).length;
    final foeMoves = MorrisEngine.legalMoves(board, reserve, foe).length;
    score += (myMoves - foeMoves) * 4.0;

    final myOpen = _openMills(board, reserve, p);
    final foeOpen = _openMills(board, reserve, foe);
    score += (myOpen - foeOpen) * 25.0;

    final myClosed = MorrisEngine.millsOn(board, p).length;
    final foeClosed = MorrisEngine.millsOn(board, foe).length;
    score += (myClosed - foeClosed) * 10.0;

    var myHot = 0, foeHot = 0;
    for (final i in MorrisBoard.hotPoints) {
      if (board[i] == p) {
        myHot++;
      } else if (board[i] == foe) {
        foeHot++;
      }
    }
    score += (myHot - foeHot) * 3.0;

    // Phase awareness: in placement, prize inner-square points and corners.
    if (!MorrisEngine.placementDone(reserve)) {
      for (var i = 16; i < 24; i++) {
        if (board[i] == p) score += 3;
        if (board[i] == foe) score -= 3;
      }
      for (final c in const [0, 2, 4, 6, 8, 10, 12, 14]) {
        if (board[c] == p) score += 2;
        if (board[c] == foe) score -= 2;
      }
    }
    return score;
  }

  /// Open mill = two of [p]'s men with the third point empty and reachable.
  static int _openMills(List<int> board, List<int> reserve, int p) {
    var n = 0;
    final placing = reserve[p] > 0;
    final flying = MorrisEngine.isFlying(board, reserve, p);
    for (final mill in MorrisBoard.mills) {
      var mine = 0;
      var empty = 0;
      var emptyIdx = -1;
      for (final i in mill) {
        if (board[i] == p) {
          mine++;
        } else if (board[i] == -1) {
          empty++;
          emptyIdx = i;
        }
      }
      if (mine != 2 || empty != 1) continue;
      if (placing || flying) {
        n++;
        continue;
      }
      // Reachable: some man of p can slide to the empty point.
      for (var f = 0; f < 24; f++) {
        if (board[f] == p && MorrisBoard.adj[f].contains(emptyIdx)) {
          n++;
          break;
        }
      }
    }
    return n;
  }
}

class _NodeBudget {
  final int max;
  int used = 0;
  _NodeBudget(this.max);
  void tick() => used++;
  bool get ok => used < max;
}
