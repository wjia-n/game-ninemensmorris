/// Game-over screen: VICTORY / DEFEAT / DRAW cartouche, parchment stat
/// tablet (mills, captures, moves, duration, stars) and REMATCH / MAIN MENU
/// tablets — per the Stitch game-over screen.
library;

import 'package:flutter/material.dart';

import '../../engine/engine.dart';
import '../../state/game_controller.dart';
import '../lapidary.dart';
import '../widgets.dart';

class GameOverScreen extends StatelessWidget {
  final GameController controller;
  const GameOverScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isDraw = c.winner == 'draw';
    final won = !isDraw &&
        (c.mode == GameMode.twoPlayer ||
            c.winner == '${c.humanSeat}');
    final title = isDraw ? 'DRAW' : (won ? 'VICTORY' : 'DEFEAT');
    final mills = c.snap.millsFormedBy.where((p) => p == c.humanSeat).length;
    final captures = c.snap.capturesBy.where((p) => p == c.humanSeat).length;
    final menLeft = MorrisEngine.pieceCount(c.snap.board, c.humanSeat) +
        c.snap.reserve[c.humanSeat];
    final stars = !isDraw &&
            won &&
            c.mode == GameMode.vsAi
        ? (menLeft >= 5 ? 3 : (menLeft >= 3 ? 2 : 1))
        : 0;

    return Scaffold(
      body: VaultBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Cartouche(
                    title: title,
                    subtitle: c.endReasonLabel().toUpperCase(),
                    fontSize: 36,
                  ),
                  const SizedBox(height: 16),
                  const EngravedDivider(),
                  ParchmentPanel(
                    child: Column(
                      children: [
                        _statRow('Mills formed', '$mills'),
                        _statRow('Men captured', '$captures'),
                        _statRow('Moves played', '${c.snap.plies}'),
                        if (stars > 0) _statRow('Stars earned', '★' * stars),
                        const SizedBox(height: 4),
                        Text(
                          isDraw
                              ? 'The stones rest. Neither side yields.'
                              : (won
                                  ? 'Honor and cunning prevail across the sacred lines.'
                                  : 'The Stone Mind claims this duel. Study the lines, return stronger.'),
                          textAlign: TextAlign.center,
                          style: Lapidary.body(13,
                              color: Lapidary.sepiaInk.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BronzeTablet(
                    label: 'REMATCH',
                    sublabel: 'THE STONES CALL AGAIN',
                    onTap: () async {
                      await c.startNew(
                          mode: c.mode,
                          difficulty: c.difficulty,
                          humanSeat: c.humanSeat);
                      if (context.mounted) {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        Navigator.of(context).pushNamed('/game');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  BronzeTablet(
                    label: 'MAIN MENU',
                    fontSize: 16,
                    onTap: () {
                      c.quitToMenu();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label.toUpperCase(),
                  style: Lapidary.letterpress(12, weight: FontWeight.bold))),
          Text(value,
              style: Lapidary.letterpress(17, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}
