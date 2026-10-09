/// Per-side player trays: each seat owns its own tray showing the player's
/// (renameable) name, pieces in hand (reserve), men on the board, and a
/// verdigris active-player glow on whose turn it is. The bot's tray narrates
/// its staged beats ("X studies the stones…") — no turn is ever silent.
library;

import 'package:flutter/material.dart';

import '../../engine/engine.dart';
import '../../state/game_controller.dart';
import '../../state/settings.dart';
import '../../theme/morris_themes.dart';
import '../lapidary.dart';

class SideTrays extends StatelessWidget {
  final GameController controller;
  const SideTrays({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tray(0)),
        const SizedBox(width: 10),
        Expanded(child: _tray(1)),
      ],
    );
  }

  Widget _tray(int seat) {
    final c = controller;
    final active = !c.gameOver && c.turn == seat && !c.capturePending;
    final inHand = c.reserve[seat];
    final onBoard = MorrisEngine.pieceCount(c.board, seat);
    final isBot = c.mode == GameMode.vsAi && seat != c.humanSeat;
    final name = c.seatName(seat);
    final theme = SettingsStore.I.activeTheme;
    final seatColor = seat == 0 ? theme.bronze : theme.bone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.parchment.withValues(alpha: active ? 1.0 : 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? theme.verdigris : theme.sepiaInk.withValues(alpha: 0.25),
          width: active ? 2.2 : 1.2,
        ),
        boxShadow: [
          if (active)
            BoxShadow(
              color: theme.verdigris.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniToken(seat, seatColor, theme),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isBot ? '$name · BOT' : name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Lapidary.letterpress(13, weight: FontWeight.bold)
                      .copyWith(color: theme.sepiaInk),
                ),
              ),
              if (active)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.verdigris,
                    boxShadow: [
                      BoxShadow(
                        color: theme.verdigris.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _pipRow(inHand, seatColor, theme, label: 'in hand'),
              const SizedBox(width: 10),
              _pipRow(onBoard, seatColor, theme, label: 'on board', dim: true),
            ],
          ),
          if (isBot && c.botBusy && c.turn == seat && c.botNarrative.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                c.botNarrative,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Lapidary.body(11, color: theme.verdigris),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pipRow(int count, Color seatColor, MorrisTheme theme,
      {required String label, bool dim = false}) {
    const maxPips = 9;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              for (var i = 0; i < maxPips; i++)
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < count
                        ? seatColor
                        : theme.sepiaInk.withValues(alpha: 0.14),
                    border: Border.all(
                      color: theme.sepiaInk.withValues(alpha: 0.3),
                      width: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$count $label',
            style: Lapidary.body(10,
                color: theme.sepiaInk.withValues(alpha: dim ? 0.6 : 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _miniToken(int seat, Color seatColor, MorrisTheme theme) {
    final dark = seat == 0 ? theme.bronzeDark : theme.boneDark;
    final light = seat == 0 ? theme.bronzeLight : const Color(0xFFF2E8D6);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [light, seatColor, dark],
        ),
        border: Border.all(color: theme.sepiaInk.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 2),
              blurRadius: 2),
        ],
      ),
    );
  }
}
