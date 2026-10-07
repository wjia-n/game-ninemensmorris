import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Nine Mens Morris — place, slide, fly, mill and capture.
class NineMensMorrisScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const NineMensMorrisScreen({super.key, required this.players, required this.callbacks});

  @override
  State<NineMensMorrisScreen> createState() => _NineMensMorrisScreenState();
}

class _NineMensMorrisScreenState extends State<NineMensMorrisScreen>
    with SingleTickerProviderStateMixin {
  // 24 points on a 7x7 grid (col,row).
  static const _xy = [
    [0, 0], [3, 0], [6, 0], [6, 3], [6, 6], [3, 6], [0, 6], [0, 3],
    [1, 1], [3, 1], [5, 1], [5, 3], [5, 5], [3, 5], [1, 5], [1, 3],
    [2, 2], [3, 2], [4, 2], [4, 3], [4, 4], [3, 4], [2, 4], [2, 3],
  ];
  static const _adj = [
    [1, 7], [0, 2, 9], [1, 3], [2, 4, 11], [3, 5], [4, 6, 13], [5, 7], [0, 6, 15],
    [9, 15], [8, 10, 1], [9, 11], [10, 12, 3], [11, 13], [12, 14, 5], [13, 15],
    [8, 14, 7], [17, 23], [16, 18, 9], [17, 19], [18, 20, 11], [19, 21],
    [20, 22, 13], [21, 23], [16, 22, 15],
  ];
  static const _mills = [
    [0, 1, 2], [2, 3, 4], [4, 5, 6], [6, 7, 0],
    [8, 9, 10], [10, 11, 12], [12, 13, 14], [14, 15, 8],
    [16, 17, 18], [18, 19, 20], [20, 21, 22], [22, 23, 16],
    [1, 9, 17], [3, 11, 19], [5, 13, 21], [7, 15, 23],
  ];
  static const _hot = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23};

  late List<int> board; // -1 empty, else player
  late List<int> toPlace;
  int turn = 0;
  int selected = -1;
  int popIdx = -1;
  bool over = false;
  bool removing = false;
  Set<int> millGlow = {};
  final _rnd = Random();
  late AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _reset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _reset() {
    board = List.filled(24, -1);
    toPlace = [9, 9];
    turn = 0;
    selected = -1;
    popIdx = -1;
    over = false;
    removing = false;
    millGlow = {};
    widget.callbacks.setActivePlayer(0);
  }

  int _count(int p) => board.where((v) => v == p).length;

  Set<int> _millSetsOn(List<int> b, int p) {
    final s = <int>{};
    for (int i = 0; i < _mills.length; i++) {
      final m = _mills[i];
      if (b[m[0]] == p && b[m[1]] == p && b[m[2]] == p) s.add(i);
    }
    return s;
  }

  bool _flying(int p) => toPlace[p] == 0 && _count(p) == 3;

  List<List<int>> _moves(int p) {
    final ms = <List<int>>[];
    if (toPlace[p] > 0) {
      for (int i = 0; i < 24; i++) {
        if (board[i] == -1) ms.add([-1, i]);
      }
      return ms;
    }
    final fly = _flying(p);
    for (int f = 0; f < 24; f++) {
      if (board[f] != p) continue;
      for (int t = 0; t < 24; t++) {
        if (board[t] != -1) continue;
        if (fly || _adj[f].contains(t)) ms.add([f, t]);
      }
    }
    return ms;
  }

  void _tapPoint(int i) {
    if (over || widget.players[turn].isBot) return;
    if (removing) {
      if (_captureTargets().contains(i)) _doCapture(i);
      return;
    }
    if (toPlace[turn] > 0) {
      if (board[i] == -1) _applyMove(-1, i);
      return;
    }
    if (selected == -1) {
      if (board[i] == turn) {
        setState(() => selected = i);
        Sfx.tap();
      }
      return;
    }
    if (selected == i) {
      setState(() => selected = -1);
      return;
    }
    if (board[i] == turn) {
      setState(() => selected = i);
      Sfx.tap();
      return;
    }
    if (board[i] == -1 && (_flying(turn) || _adj[selected].contains(i))) {
      _applyMove(selected, i);
    }
  }

  void _applyMove(int from, int to) {
    final before = _millSetsOn(board, turn);
    if (from != -1) board[from] = -1;
    board[to] = turn;
    if (from == -1) toPlace[turn]--;
    final after = _millSetsOn(board, turn);
    final fresh = after.difference(before);
    final glow = <int>{};
    for (final mi in fresh) {
      glow.addAll(_mills[mi]);
    }
    setState(() {
      selected = -1;
      popIdx = to;
      millGlow = glow;
    });
    _pop.forward(from: 0);
    Sfx.move();
    if (fresh.isNotEmpty) {
      setState(() => removing = true);
      _maybeBot();
    } else {
      _nextTurn();
    }
  }

  List<int> _captureTargets() {
    final foe = 1 - turn;
    final foeMills = _millSetsOn(board, foe);
    final inMill = <int>{};
    for (final mi in foeMills) {
      inMill.addAll(_mills[mi]);
    }
    final all = [for (int i = 0; i < 24; i++) if (board[i] == foe) i];
    final free = all.where((i) => !inMill.contains(i)).toList();
    return free.isEmpty ? all : free;
  }

  void _doCapture(int i) {
    setState(() {
      board[i] = -1;
      removing = false;
      millGlow = {};
    });
    Sfx.click();
    final foe = 1 - turn;
    if (toPlace[0] == 0 && toPlace[1] == 0 && _count(foe) <= 2) {
      _endGame(turn);
      return;
    }
    _nextTurn();
  }

  void _nextTurn() {
    setState(() => turn = 1 - turn);
    widget.callbacks.setActivePlayer(turn);
    if (toPlace[turn] == 0) {
      if (_moves(turn).isEmpty) {
        _endGame(1 - turn, blocked: true);
        return;
      }
    }
    _maybeBot();
  }

  void _maybeBot() {
    if (over || !widget.players[turn].isBot) return;
    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted || over || !widget.players[turn].isBot) return;
      if (removing) {
        _doCapture(_botCapture());
      } else {
        final m = _botMove();
        _applyMove(m[0], m[1]);
      }
    });
  }

  List<int> _botMove() {
    final p = turn, foe = 1 - turn;
    final ms = _moves(p);
    var best = ms.first;
    var bestScore = -1e9;
    for (final m in ms) {
      final from = m[0], to = m[1];
      var score = _rnd.nextDouble() * 6;
      if (_hot.contains(to)) score += 4;
      // block foe's near-mill
      for (final mill in _mills) {
        if (!mill.contains(to)) continue;
        final others = mill.where((x) => x != to).toList();
        if (board[others[0]] == foe && board[others[1]] == foe) score += 500;
      }
      // make a mill
      final b = List<int>.from(board);
      if (from != -1) b[from] = -1;
      b[to] = p;
      if (_millSetsOn(b, p).difference(_millSetsOn(board, p)).isNotEmpty) score += 1000;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  int _botCapture() {
    final targets = _captureTargets();
    final foe = 1 - turn;
    var best = targets.first;
    var bestScore = -1e9;
    for (final t in targets) {
      var score = _rnd.nextDouble() * 4;
      for (final mill in _mills) {
        if (!mill.contains(t)) continue;
        final others = mill.where((x) => x != t).toList();
        if (board[others[0]] == foe && board[others[1]] == foe) score += 30;
      }
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }
    return best;
  }

  void _endGame(int winnerIdx, {bool blocked = false}) {
    setState(() => over = true);
    final w = widget.players[winnerIdx];
    w.score += 1;
    widget.callbacks.refreshHud();
    Sfx.win();
    widget.callbacks.finish(
      winner: w,
      headline: '${w.name} rules the mill! 🏰🎉',
      subline: blocked
          ? '${widget.players[1 - winnerIdx].name} has no moves left. Total lockdown!'
          : 'Down to two knights — a legendary victory!',
    );
  }

  String _phaseLabel() {
    if (removing) return 'MILL! Tap an enemy knight to capture 💥';
    if (toPlace[turn] > 0) return 'PLACING • ${toPlace[turn]} knights left';
    if (_flying(turn)) return 'FLYING ✈ • jump anywhere!';
    return 'MOVING • slide along the lines';
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final current = widget.players[turn];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!over) TurnBanner(player: current, action: current.isBot ? ' is scheming… 🤖' : ' • ${_phaseLabel()}'),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: t.radius,
                    boxShadow: [
                      BoxShadow(
                          color: t.primary.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Builder(
                    builder: (ctx) => GestureDetector(
                      onTapUp: (d) {
                        final box = ctx.findRenderObject() as RenderBox;
                        final idx = _MorrisPainter.cellAt(d.localPosition, box.size);
                        if (idx != null) _tapPoint(idx);
                      },
                      child: CustomPaint(
                        painter: _MorrisPainter(
                          repaint: _pop,
                          board: board,
                          players: widget.players,
                          turn: turn,
                          selected: selected,
                          removing: removing,
                          captureTargets: removing ? _captureTargets() : const [],
                          targets: _moveTargets(),
                          millGlow: millGlow,
                          popIdx: popIdx,
                          pop: _pop.value,
                          line: t.primary.withValues(alpha: 0.5),
                          dot: t.muted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Three in a row makes a mill. Mills capture knights. 👑',
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  List<int> _moveTargets() {
    if (over || removing || selected == -1 || toPlace[turn] > 0) return const [];
    if (_flying(turn)) return [for (int i = 0; i < 24; i++) if (board[i] == -1) i];
    return _adj[selected].where((i) => board[i] == -1).toList();
  }
}

class _MorrisPainter extends CustomPainter {
  final List<int> board;
  final List<Player> players;
  final int turn;
  final int selected;
  final bool removing;
  final List<int> captureTargets;
  final List<int> targets;
  final Set<int> millGlow;
  final int popIdx;
  final double pop;
  final Color line;
  final Color dot;

  _MorrisPainter({
    super.repaint,
    required this.board,
    required this.players,
    required this.turn,
    required this.selected,
    required this.removing,
    required this.captureTargets,
    required this.targets,
    required this.millGlow,
    required this.popIdx,
    required this.pop,
    required this.line,
    required this.dot,
  });

  static Offset _pt(int i, Size size) {
    const pad = 34.0;
    final s = (size.width - pad * 2) / 6;
    final ox = (size.width - s * 6) / 2;
    final oy = (size.height - s * 6) / 2;
    final xy = _NineMensMorrisScreenState._xy[i];
    return Offset(ox + xy[0] * s, oy + xy[1] * s);
  }

  static int? cellAt(Offset p, Size size) {
    const pad = 34.0;
    final s = (size.width - pad * 2) / 6;
    var bestD = 1e9;
    int? best;
    for (int i = 0; i < 24; i++) {
      final d = (p - _pt(i, size)).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return bestD <= s * 0.45 ? best : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final adj = _NineMensMorrisScreenState._adj;
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 24; i++) {
      for (final j in adj[i]) {
        if (j > i) canvas.drawLine(_pt(i, size), _pt(j, size), linePaint);
      }
    }
    // move target dots
    for (final i in targets) {
      canvas.drawCircle(_pt(i, size), 6, Paint()..color = players[turn].color);
    }
    for (int i = 0; i < 24; i++) {
      final p = _pt(i, size);
      final v = board[i];
      if (v == -1) {
        canvas.drawCircle(p, 5.5, Paint()..color = dot);
        continue;
      }
      var r = 13.0;
      if (i == popIdx) {
        final e = Curves.elasticOut.transform(pop.clamp(0.0, 1.0));
        r = 13.0 * (0.3 + 0.7 * e);
      }
      if (millGlow.contains(i)) {
        canvas.drawCircle(
            p,
            r + 7,
            Paint()
              ..color = players[v].color.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
      }
      if (i == selected) {
        canvas.drawCircle(
            p,
            r + 5,
            Paint()
              ..color = players[v].color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
      if (removing && captureTargets.contains(i)) {
        canvas.drawCircle(
            p,
            r + 5,
            Paint()
              ..color = players[turn].color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
      canvas.drawCircle(p, r, Paint()..color = players[v].color);
      canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _MorrisPainter old) => true;
}
