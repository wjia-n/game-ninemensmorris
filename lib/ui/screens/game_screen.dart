/// Gameplay screen: parchment status panel (turn, reserves, phase), the full
/// carved board, icon-only sandstone toolbar (undo, hint, draw, restart,
/// pause, settings) and a phase-hint strip — per the Stitch gameplay screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../audio/sound.dart';
import '../../engine/engine.dart';
import '../../state/game_controller.dart';
import '../board_painter.dart';
import '../lapidary.dart';
import '../widgets.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;
  const GameScreen({super.key, required this.controller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _pop;
  int _seenPlaced = -2;
  String? _toast;
  Timer? _toastTimer;

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _pop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _c.addListener(_onGameChanged);
    _c.onGameOver = _onGameOver;
    _seenPlaced = _c.lastPlaced;
  }

  @override
  void dispose() {
    _c.removeListener(_onGameChanged);
    _c.onGameOver = null;
    _toastTimer?.cancel();
    _pulse.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    if (_c.lastPlaced != _seenPlaced) {
      _seenPlaced = _c.lastPlaced;
      if (_seenPlaced >= 0) _pop.forward(from: 0);
    }
  }

  void _onGameOver() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pushNamed('/gameover');
    });
  }

  void _showToast(String msg) {
    _toastTimer?.cancel();
    setState(() => _toast = msg);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VaultBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Stack(
                children: [
                  Column(
                    children: [
                      _statusPanel(),
                      Expanded(child: _board()),
                      _hintStrip(),
                      _toolbar(),
                      const SizedBox(height: 8),
                    ],
                  ),
                  if (_c.paused) _pauseOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- status panel ------------------------------------------------------------------
  Widget _statusPanel() {
    final bronzeMen =
        MorrisEngine.pieceCount(_c.board, 0) + _c.reserve[0];
    final boneMen = MorrisEngine.pieceCount(_c.board, 1) + _c.reserve[1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: ParchmentPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            ReserveChip(
                count: _c.reserve[0], seat: 0, label: 'BRONZE · $bronzeMen'),
            Expanded(child: _turnBanner()),
            ReserveChip(
                count: _c.reserve[1], seat: 1, label: 'BONE · $boneMen'),
          ],
        ),
      ),
    );
  }

  Widget _turnBanner() {
    String label;
    Color accent = Lapidary.sepiaInk;
    if (_c.gameOver) {
      label = _c.winnerLabel().toUpperCase();
    } else if (_c.capturePending) {
      label = 'MILL!';
      accent = Lapidary.verdigris;
    } else if (_c.mode == GameMode.vsAi) {
      label = _c.turn == _c.humanSeat ? 'YOUR TURN' : 'STONE MIND';
    } else {
      label = _c.turn == 0 ? 'BRONZE TO MOVE' : 'BONE TO MOVE';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: Lapidary.letterpress(17, weight: FontWeight.bold)
                .copyWith(color: accent)),
        const SizedBox(height: 2),
        Text(
          _c.gameOver
              ? _c.endReasonLabel()
              : (_c.capturePending
                  ? 'Choose an enemy man to capture'
                  : _c.phaseLabel()),
          textAlign: TextAlign.center,
          style: Lapidary.body(11),
        ),
      ],
    );
  }

  // --- board ------------------------------------------------------------------
  Widget _board() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _pop, _c]),
            builder: (_, _) => GestureDetector(
              onTapUp: (d) {
                final boardBox = _boardKey.currentContext?.findRenderObject()
                    as RenderBox?;
                if (boardBox == null || !boardBox.size.isFinite) return;
                final local = boardBox.globalToLocal(d.globalPosition);
                final idx = BoardPainter.cellAt(local, boardBox.size);
                if (idx != null) _c.tapPoint(idx);
              },
              child: CustomPaint(
                key: _boardKey,
                painter: BoardPainter(
                  repaint: _pulse,
                  board: _c.board,
                  turn: _c.turn,
                  selected: _c.selected,
                  captureTargets: _c.captureTargets,
                  moveTargets: _c.moveTargets,
                  millFlash: _c.millFlash,
                  popIdx: _c.lastPlaced,
                  popT: _pop.value,
                  pulse: _pulse.value,
                  hintFrom: _c.hintFrom,
                  hintTo: _c.hintTo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final _boardKey = GlobalKey();

  // --- hint strip ------------------------------------------------------------------
  Widget _hintStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: ParchmentPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Center(
          child: Text(
            _toast ?? _c.phaseLabel(),
            textAlign: TextAlign.center,
            style: Lapidary.body(12,
                color: _toast != null
                    ? Lapidary.verdigris
                    : Lapidary.sepiaInk.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }

  // --- toolbar ------------------------------------------------------------------
  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ReliefIconButton(
            icon: Icons.undo,
            tooltip: 'Undo last move',
            disabled: !_c.canUndo,
            onTap: _c.undo,
          ),
          ReliefIconButton(
            icon: Icons.lightbulb_outline,
            tooltip: 'Hint',
            disabled: _c.gameOver || _c.isBotTurn,
            onTap: _c.hint,
          ),
          ReliefIconButton(
            icon: Icons.handshake_outlined,
            tooltip: 'Offer draw',
            disabled: _c.gameOver,
            onTap: _offerDraw,
          ),
          ReliefIconButton(
            icon: Icons.refresh,
            tooltip: 'Restart',
            onTap: _confirmRestart,
          ),
          ReliefIconButton(
            icon: Icons.pause,
            tooltip: 'Pause',
            disabled: _c.gameOver,
            onTap: _c.pause,
          ),
          ReliefIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
    );
  }

  void _offerDraw() {
    final res = _c.offerDraw();
    if (res == 'accepted') {
      _showToast('The Stone Mind accepts your draw.');
    } else if (res == 'declined') {
      Sound.I.invalid();
      _showToast('No draw yet — the stones demand a victor.');
    } else {
      // Two players: ask the other soul at the table.
      final other = _c.turn == 0 ? 'Bone' : 'Bronze';
      showDialog(
        context: context,
        builder: (ctx) => _StoneDialog(
          title: 'A DRAW IS OFFERED',
          body: '$other, do you accept the draw?',
          actions: [
            ('REFUSE', () => Navigator.of(ctx).pop()),
            ('ACCEPT', () {
              Navigator.of(ctx).pop();
              _c.acceptDrawOffer();
            }),
          ],
        ),
      );
    }
  }

  void _confirmRestart() {
    showDialog(
      context: context,
      builder: (ctx) => _StoneDialog(
        title: 'RESTART THE DUEL?',
        body: 'The current board will be swept away.',
        actions: [
          ('KEEP PLAYING', () => Navigator.of(ctx).pop()),
          ('RESTART', () {
            Navigator.of(ctx).pop();
            _c.startNew(
                mode: _c.mode,
                difficulty: _c.difficulty,
                humanSeat: _c.humanSeat);
          }),
        ],
      ),
    );
  }

  // --- pause overlay ------------------------------------------------------------------
  Widget _pauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Cartouche(title: 'PAUSED', fontSize: 28),
              const SizedBox(height: 16),
              BronzeTablet(
                  label: 'RESUME',
                  onTap: _c.resume),
              const SizedBox(height: 10),
              BronzeTablet(
                label: 'RESTART',
                fontSize: 15,
                onTap: () {
                  _c.resume();
                  _c.startNew(
                      mode: _c.mode,
                      difficulty: _c.difficulty,
                      humanSeat: _c.humanSeat);
                },
              ),
              const SizedBox(height: 10),
              BronzeTablet(
                label: 'HOW TO PLAY',
                fontSize: 15,
                onTap: () =>
                    Navigator.of(context).pushNamed('/howto'),
              ),
              const SizedBox(height: 10),
              BronzeTablet(
                label: 'SETTINGS',
                fontSize: 15,
                onTap: () =>
                    Navigator.of(context).pushNamed('/settings'),
              ),
              const SizedBox(height: 10),
              BronzeTablet(
                label: 'QUIT TO MENU',
                fontSize: 15,
                onTap: () {
                  _c.quitToMenu();
                  Navigator.of(context)
                      .popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small parchment dialog with bronze action tablets.
class _StoneDialog extends StatelessWidget {
  final String title;
  final String body;
  final List<(String, VoidCallback)> actions;
  const _StoneDialog(
      {required this.title, required this.body, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ParchmentPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: Lapidary.letterpress(18, weight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(body,
                textAlign: TextAlign.center, style: Lapidary.body(14)),
            const SizedBox(height: 16),
            for (final (label, fn) in actions) ...[
              BronzeTablet(label: label, fontSize: 14, onTap: fn),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
