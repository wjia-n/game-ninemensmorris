/// Game flow controller: turns, selection, captures, bot scheduling, undo,
/// hints, draws, pause/resume, persistence and statistics.
///
/// Turn-state ownership:
/// - The pure rules live in [MorrisEngine] (placement / movement / flying,
///   mills, capture protection, win/draw detection). The controller never
///   invents rule outcomes.
/// - Turn *flow* (who acts, when the bot acts, staged bot animation beats)
///   is owned here by an explicit [BotStage] state machine plus a watchdog
///   timer. Stuck states are impossible by construction: every stage has a
///   live timer or a watchdog recovery, and the watchdog re-schedules a bot
///   turn whenever one is due but nothing is in flight.
///
/// Bot visibility: bot turns are never instant. Each bot turn walks through
/// visible stages — thinking (narration) → acting (the move animates on the
/// board) → capturing (mill flash, then the seized man animates out) — with
/// a narration line for every beat.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/sound.dart';
import '../engine/ai.dart';
import '../engine/engine.dart';
import '../engine/morris.dart';
import 'settings.dart';
import 'stats.dart';

enum GameMode { vsAi, twoPlayer }

/// Bot turn stages. `idle` means no bot work is in flight; every other stage
/// is owned by a live delayed future, and the watchdog recovers `idle`-with-
/// bot-to-move (the only stage the watchdog is allowed to advance).
enum BotStage { idle, scheduled, thinking, acting, capturing }

class PendingPly {
  final int from;
  final int to;
  final List<int> board; // board with the move applied, capture unresolved
  final List<int> reserve;
  final bool formedMill;
  const PendingPly(this.from, this.to, this.board, this.reserve, this.formedMill);
}

class GameController extends ChangeNotifier {
  GameController();

  final Random _rng = Random();
  int _gameId = 0;
  bool _disposed = false;

  // --- match config ----------------------------------------------------------
  GameMode mode = GameMode.vsAi;
  Difficulty difficulty = Difficulty.medium;
  int humanSeat = 0; // which seat the human plays in vsAi

  // --- match state ------------------------------------------------------------
  MorrisSnapshot snap = MorrisSnapshot.initial();
  final List<MorrisSnapshot> _history = [];
  PendingPly? pending; // human formed a mill, awaiting capture pick
  int selected = -1;
  String? winner; // '0' | '1' | 'draw'
  String? endReason; // 'reduction' | 'blocked' | 'repetition' | 'no-progress' | 'agreement' | 'resign'
  bool paused = false;
  DateTime? _startedAt;

  /// True while a game session is live on the game screen. Cleared by
  /// [quitToMenu] so the watchdog never advances a saved game in the menu.
  bool _inGame = false;

  // --- bot turn state machine --------------------------------------------------
  BotStage _botStage = BotStage.idle;
  BotStage get botStage => _botStage;
  bool get botBusy => _botStage != BotStage.idle;

  /// Narration line for the current bot beat ("Sargon studies the stones…").
  String botNarrative = '';

  /// The bot's current move, exposed so the UI animates it visibly.
  int botFrom = -1;
  int botTo = -1;

  /// The bot's in-flight move preview: shown on the board during the acting
  /// beat so the move is visible well before the turn settles.
  PendingPly? botPreview;

  /// The man the bot is about to seize, highlighted before removal.
  int botCaptureAt = -1;

  /// Watchdog: recovers any bot turn left without a live timer.
  Timer? _watchdog;

  /// How many times the watchdog recovered a stalled bot turn (test hook).
  int watchdogRecoveries = 0;

  // --- animation / feedback transients ----------------------------------------
  int lastPlaced = -1;
  int lastFrom = -1; // origin of the last slide (for slide animation)
  int lastCaptured = -1;
  Set<int> millFlash = {};
  int? hintFrom;
  int? hintTo;

  /// Fired once when the game ends (UI navigates to the game-over screen).
  VoidCallback? onGameOver;

  static const _kSaved = 'nmm_saved_game_v1';

  // --- derived -----------------------------------------------------------------
  int get turn => snap.turn;

  /// The board as the player sees it: the bot's in-flight move (during its
  /// visible acting beat) or the human's unresolved mill preview take
  /// precedence over the settled snapshot.
  List<int> get board =>
      botPreview?.board ?? pending?.board ?? snap.board;
  List<int> get reserve =>
      botPreview?.reserve ?? pending?.reserve ?? snap.reserve;
  bool get gameOver => winner != null;
  bool get capturePending => pending != null;
  bool get isBotTurn =>
      _inGame && !gameOver && mode == GameMode.vsAi && turn != humanSeat;
  bool get inPlacement => reserve[turn] > 0;
  bool get canUndo =>
      !gameOver && !isBotTurn && !capturePending && !botBusy && _history.isNotEmpty;
  bool get placementDone => MorrisEngine.placementDone(snap.reserve);
  bool get flyingTurn => MorrisEngine.isFlying(board, reserve, turn);

  /// Display name for a seat (renameable, persisted).
  String seatName(int seat) => SettingsStore.I.playerName(seat);

  List<int> get captureTargets =>
      capturePending ? MorrisEngine.captureTargets(board, turn) : const [];

  List<int> get moveTargets => (selected == -1 || capturePending || gameOver)
      ? const []
      : MorrisEngine.destinationsFrom(board, reserve, turn, selected);

  String phaseLabel() {
    if (gameOver) return '';
    if (botBusy && botNarrative.isNotEmpty) return botNarrative;
    if (capturePending) return 'MILL! Choose an enemy man to capture';
    if (reserve[turn] > 0) {
      return 'PLACING · ${reserve[turn]} in reserve';
    }
    if (flyingTurn) return 'FLYING · leap to any free point';
    return 'MOVING · slide along the carved lines';
  }

  // --- lifecycle ---------------------------------------------------------------
  Future<void> startNew({
    required GameMode mode,
    required Difficulty difficulty,
    required int humanSeat,
  }) async {
    _gameId++;
    this.mode = mode;
    this.difficulty = difficulty;
    this.humanSeat = humanSeat;
    snap = MorrisSnapshot.initial();
    if (!SettingsStore.I.humanFirst && mode == GameMode.vsAi) {
      snap = MorrisSnapshot(
        board: snap.board,
        reserve: snap.reserve,
        turn: 1,
        plies: 0,
        pliesNoProgress: 0,
        positionHistory: snap.positionHistory,
        millsFormedBy: snap.millsFormedBy,
        capturesBy: snap.capturesBy,
      );
      this.humanSeat = 1;
    } else {
      this.humanSeat = mode == GameMode.vsAi ? 0 : humanSeat;
    }
    _history.clear();
    pending = null;
    selected = -1;
    winner = null;
    endReason = null;
    paused = false;
    lastPlaced = -1;
    lastFrom = -1;
    lastCaptured = -1;
    millFlash = {};
    hintFrom = null;
    hintTo = null;
    _botStage = BotStage.idle;
    botNarrative = '';
    botFrom = -1;
    botTo = -1;
    botPreview = null;
    botCaptureAt = -1;
    _inGame = true;
    _startedAt = DateTime.now();
    _evalHistory.clear();
    _startWatchdog();
    Sound.I.gameStart();
    Sound.I.gameMusic();
    await _saveGame();
    notifyListeners();
    _scheduleBot();
  }

  /// Returns true when a saved in-progress game exists.
  Future<bool> hasSavedGame() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_kSaved);
  }

  Future<bool> continueSaved() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSaved);
    if (raw == null) return false;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      _gameId++;
      mode = GameMode.values[(j['mode'] as int?) ?? 0];
      difficulty = Difficulty.values[(j['difficulty'] as int?) ?? 1];
      humanSeat = (j['humanSeat'] as int?) ?? 0;
      snap = MorrisSnapshot.fromJson(j['snapshot'] as Map<String, Object?>);
      _history.clear();
      pending = null;
      selected = -1;
      winner = null;
      endReason = null;
      paused = false;
      _botStage = BotStage.idle;
      botNarrative = '';
      botFrom = -1;
      botTo = -1;
      botCaptureAt = -1;
      _inGame = true;
      _startedAt = DateTime.fromMillisecondsSinceEpoch(
          (j['startedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch);
      _evalHistory.clear();
      _startWatchdog();
      Sound.I.gameMusic();
      notifyListeners();
      _scheduleBot();
      return true;
    } catch (_) {
      await p.remove(_kSaved);
      return false;
    }
  }

  Future<void> _saveGame() async {
    if (gameOver) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kSaved,
        jsonEncode({
          'mode': mode.index,
          'difficulty': difficulty.index,
          'humanSeat': humanSeat,
          'snapshot': snap.toJson(),
          'startedAt': (_startedAt ?? DateTime.now()).millisecondsSinceEpoch,
        }));
  }

  Future<void> _clearSaved() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSaved);
  }

  // --- watchdog -----------------------------------------------------------------
  /// The watchdog owns liveness: every 2s it audits the turn state machine.
  /// The only recoverable stall is "bot to move with nothing in flight"
  /// (a dropped timer, e.g. across an app-background race); in that case it
  /// re-schedules the bot turn and counts the recovery. All other states
  /// either have a live timer or are human-driven.
  void _startWatchdog() {
    _watchdog?.cancel();
    if (_disposed) return;
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      _watchdogTick();
    });
  }

  void _watchdogTick() {
    if (_disposed || gameOver || paused || !_inGame) return;
    // Invariant audit: turn is always a valid seat.
    assert(snap.turn == 0 || snap.turn == 1, 'corrupt turn ${snap.turn}');
    if (!isBotTurn) return;
    if (_botStage == BotStage.idle) {
      watchdogRecoveries++;
      _scheduleBot();
    }
  }

  // --- human input --------------------------------------------------------------
  void tapPoint(int i) {
    if (gameOver || paused || isBotTurn || botBusy) return;
    Sound.I.select();
    if (capturePending) {
      if (captureTargets.contains(i)) {
        _resolveHumanCapture(i);
      } else {
        Sound.I.invalid();
      }
      return;
    }
    if (reserve[turn] > 0) {
      if (board[i] == -1) {
        _beginHumanPly(-1, i);
      } else {
        Sound.I.invalid();
      }
      return;
    }
    if (selected == -1) {
      if (board[i] == turn) {
        selected = i;
        notifyListeners();
      }
      return;
    }
    if (selected == i) {
      selected = -1;
      notifyListeners();
      return;
    }
    if (board[i] == turn) {
      selected = i;
      notifyListeners();
      return;
    }
    if (board[i] == -1 &&
        (flyingTurn || MorrisBoard.adj[selected].contains(i))) {
      _beginHumanPly(selected, i);
    } else {
      Sound.I.invalid();
    }
  }

  void _beginHumanPly(int from, int to) {
    final preview = _preview(from, to);
    lastPlaced = to;
    lastFrom = from;
    selected = -1;
    hintFrom = null;
    hintTo = null;
    if (preview.formedMill) {
      pending = preview;
      millFlash = _millPoints(board, turn);
      Sound.I.mill();
    } else {
      _finalizePly(preview, -1);
    }
    notifyListeners();
  }

  void _resolveHumanCapture(int at) {
    final p = pending;
    if (p == null) return;
    pending = null;
    lastCaptured = at;
    Sound.I.capture();
    _finalizePly(p, at);
    notifyListeners();
  }

  /// Applies the (possibly capture-resolved) ply through the pure engine.
  void _finalizePly(PendingPly ply, int capture) {
    botPreview = null;
    _history.add(snap);
    final mover = snap.turn;
    final wasFlying = ply.from != -1 &&
        MorrisEngine.isFlying(snap.board, snap.reserve, mover);
    final result = MorrisEngine.applyPly(snap, ply.from, ply.to, capture);
    snap = result.snapshot;
    millFlash = result.formedMill ? _millPoints(snap.board, mover) : {};
    // Sounds for the completed ply.
    if (capture == -1) {
      if (ply.from == -1) {
        Sound.I.place();
      } else if (wasFlying) {
        Sound.I.fly();
      } else {
        Sound.I.move();
      }
    }
    _evalHistory.add(MorrisAi.evaluate(
        snap.board, snap.reserve, mode == GameMode.vsAi ? 1 - humanSeat : 0));
    if (result.winner != null) {
      _finishGame(result.winner!, result.endReason);
    } else {
      _saveGame();
      _scheduleBot();
    }
    notifyListeners();
  }

  Set<int> _millPoints(List<int> board, int p) {
    final pts = <int>{};
    for (final mi in MorrisEngine.millsOn(board, p)) {
      pts.addAll(MorrisBoard.mills[mi]);
    }
    return pts;
  }

  PendingPly _preview(int from, int to) {
    final b = List<int>.from(snap.board);
    final r = List<int>.from(snap.reserve);
    final p = snap.turn;
    final before = MorrisEngine.millsOn(b, p);
    if (from != -1) b[from] = -1;
    b[to] = p;
    if (from == -1) r[p]--;
    final formed = MorrisEngine.millsOn(b, p).difference(before).isNotEmpty;
    return PendingPly(from, to, b, r, formed);
  }

  // --- bot: fully visible staged turns --------------------------------------------
  void _scheduleBot() {
    if (!isBotTurn || gameOver || _botStage != BotStage.idle || !_inGame) {
      return;
    }
    _botStage = BotStage.scheduled;
    final id = _gameId;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (id != _gameId || _disposed) {
        _botStage = BotStage.idle;
        return;
      }
      if (!isBotTurn || gameOver || paused) {
        // Turn conditions changed (undo/pause/quit): release the stage so the
        // watchdog or the next legitimate trigger can re-schedule.
        _botStage = BotStage.idle;
        notifyListeners();
        return;
      }
      _botThink();
    });
  }

  void _botThink() {
    final id = _gameId;
    final p = turn;
    _botStage = BotStage.thinking;
    botNarrative = '${seatName(p)} studies the stones…';
    botFrom = -1;
    botTo = -1;
    botPreview = null;
    botCaptureAt = -1;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (id != _gameId || _disposed) {
        _botStage = BotStage.idle;
        return;
      }
      if (!isBotTurn || gameOver || paused) {
        _botStage = BotStage.idle;
        botNarrative = '';
        notifyListeners();
        return;
      }
      _botAct();
    });
  }

  void _botAct() {
    final p = turn;
    final name = seatName(p);
    final m = MorrisAi.chooseMove(board, reserve, p, difficulty, _rng);
    if (m[0] == -1 && m[1] == -1) {
      // Unreachable: blocked losses are declared by the engine at the end of
      // the previous ply, so a bot never faces zero moves. Release cleanly.
      _botStage = BotStage.idle;
      botNarrative = '';
      notifyListeners();
      return;
    }
    final preview = _preview(m[0], m[1]);
    _botStage = BotStage.acting;
    botPreview = preview;
    botFrom = m[0];
    botTo = m[1];
    lastPlaced = m[1];
    lastFrom = m[0];
    selected = -1;
    botNarrative = m[0] == -1
        ? '$name sets a man upon the stone…'
        : (MorrisEngine.isFlying(board, reserve, p)
            ? '$name takes flight across the board…'
            : '$name slides a man along the carved line…');
    Sound.I.select();
    notifyListeners();
    final id = _gameId;
    // Visible beat: the move sits on the board before anything else happens.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (id != _gameId || _disposed || gameOver) return;
      if (preview.formedMill) {
        _botStage = BotStage.capturing;
        final cap = MorrisAi.chooseCapture(preview.board, p, difficulty, _rng);
        botCaptureAt = cap;
        millFlash = _millPoints(preview.board, p);
        botNarrative = 'MILL! $name seizes a rival man…';
        Sound.I.mill();
        notifyListeners();
        // Visible beat: the doomed man is highlighted before it is removed.
        Future.delayed(const Duration(milliseconds: 850), () {
          if (id != _gameId || _disposed || gameOver) return;
          _botStage = BotStage.idle;
          botPreview = null;
          botFrom = -1;
          botTo = -1;
          botCaptureAt = -1;
          botNarrative = '';
          lastCaptured = cap;
          Sound.I.capture();
          _finalizePly(preview, cap);
        });
      } else {
        _botStage = BotStage.idle;
        botPreview = null;
        botFrom = -1;
        botTo = -1;
        botNarrative = '';
        _finalizePly(preview, -1);
      }
    });
  }

  // --- undo / hint -----------------------------------------------------------------
  void undo() {
    if (!canUndo) return;
    final prev = _history.removeLast();
    // Undo counts as a new move for the no-progress counter (RULES.md §12.5).
    snap = MorrisSnapshot(
      board: prev.board,
      reserve: prev.reserve,
      turn: prev.turn,
      plies: prev.plies,
      pliesNoProgress: prev.pliesNoProgress + 1,
      positionHistory: prev.positionHistory,
      millsFormedBy: prev.millsFormedBy,
      capturesBy: prev.capturesBy,
    );
    pending = null;
    selected = -1;
    lastPlaced = -1;
    lastFrom = -1;
    lastCaptured = -1;
    millFlash = {};
    if (_evalHistory.isNotEmpty) _evalHistory.removeLast();
    Sound.I.undo();
    _saveGame();
    notifyListeners();
  }

  void hint() {
    if (gameOver || paused || isBotTurn || capturePending || botBusy) return;
    final m = MorrisAi.chooseMove(board, reserve, turn, Difficulty.medium, _rng);
    if (m[1] == -1) return;
    hintFrom = m[0];
    hintTo = m[1];
    Sound.I.click();
    notifyListeners();
    final id = _gameId;
    Future.delayed(const Duration(seconds: 3), () {
      if (id != _gameId) return;
      hintFrom = null;
      hintTo = null;
      notifyListeners();
    });
  }

  // --- draws --------------------------------------------------------------------------
  final List<double> _evalHistory = [];

  /// Human offers a draw. Vs AI: accepted when the AI's evaluation has stayed
  /// within ±30 (≈ ±0.3 pawns) for the last 10 plies (RULES.md §10).
  /// Returns 'accepted' | 'declined' | 'ask' (2P: UI asks the other player).
  String offerDraw() {
    if (gameOver || !placementDone) return 'declined';
    if (mode == GameMode.twoPlayer) return 'ask';
    final recent = _evalHistory.length >= 10
        ? _evalHistory.sublist(_evalHistory.length - 10)
        : _evalHistory;
    // _evalHistory stores evals from the AI seat's perspective in vsAI.
    final ok = recent.length >= 10 && recent.every((e) => e.abs() <= 30);
    if (ok) {
      _finishGame('draw', 'agreement');
      return 'accepted';
    }
    return 'declined';
  }

  void acceptDrawOffer() => _finishGame('draw', 'agreement');

  // --- pause / resume --------------------------------------------------------------------
  void pause() {
    if (gameOver || paused) return;
    paused = true;
    _saveGame();
    Sound.I.duckMusic();
    Sound.I.onLifecyclePause();
    notifyListeners();
  }

  void resume() {
    if (!paused) return;
    paused = false;
    Sound.I.unduckMusic();
    Sound.I.onLifecycleResume();
    notifyListeners();
    _scheduleBot();
  }

  void quitToMenu() {
    _gameId++;
    _botStage = BotStage.idle;
    botNarrative = '';
    _inGame = false;
    _saveGame();
    Sound.I.menuMusic();
  }

  @override
  void dispose() {
    _disposed = true;
    _gameId++;
    _watchdog?.cancel();
    super.dispose();
  }

  // --- game end ------------------------------------------------------------------------------
  void _finishGame(String win, String? reason) {
    _gameId++;
    _botStage = BotStage.idle;
    botNarrative = '';
    winner = win;
    endReason = reason;
    pending = null;
    selected = -1;
    millFlash = {};
    _clearSaved();
    final humanWon = mode == GameMode.vsAi && win == '$humanSeat';
    final humanLost = mode == GameMode.vsAi && win == '${1 - humanSeat}';
    if (win == 'draw') {
      Sound.I.draw();
    } else if (mode == GameMode.vsAi) {
      if (humanWon) {
        Sound.I.win();
      } else {
        Sound.I.lose();
      }
    } else {
      Sound.I.win();
    }
    // Statistics.
    final mills = snap.millsFormedBy.where((p) => p == humanSeat).length;
    final caps = snap.capturesBy.where((p) => p == humanSeat).length;
    var stars = 0;
    if (mode == GameMode.vsAi && humanWon) {
      final menLeft = MorrisEngine.pieceCount(snap.board, humanSeat) +
          snap.reserve[humanSeat];
      stars = menLeft >= 5 ? 3 : (menLeft >= 3 ? 2 : 1);
    }
    final outcome = win == 'draw'
        ? 'draw'
        : (mode == GameMode.twoPlayer
            ? (win == '0' ? 'win' : 'loss')
            : (humanWon ? 'win' : (humanLost ? 'loss' : 'draw')));
    StatsStore.I.record(GameResult(
      outcome: outcome,
      millsFormed: mills,
      captures: caps,
      plies: snap.plies,
      durationSec: _startedAt == null
          ? 0
          : DateTime.now().difference(_startedAt!).inSeconds,
      stars: stars,
      difficulty: difficulty,
      vsAi: mode == GameMode.vsAi,
    ));
    notifyListeners();
    onGameOver?.call();
  }

  String winnerLabel() {
    if (winner == null) return '';
    if (winner == 'draw') return 'Draw';
    if (mode == GameMode.vsAi) {
      return winner == '$humanSeat' ? 'Victory' : 'Defeat';
    }
    return '${seatName(int.parse(winner!))} Wins';
  }

  String endReasonLabel() {
    switch (endReason) {
      case 'reduction':
        return 'The rival was ground down to two men.';
      case 'blocked':
        return 'The rival has no legal move left. Total lockdown.';
      case 'repetition':
        return 'The same position arose three times.';
      case 'no-progress':
        return 'Fifty plies passed with no mill and no capture.';
      case 'agreement':
        return 'Both sides agreed to lay down their stones.';
      default:
        return 'The stones have spoken.';
    }
  }
}
