import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const NineMensMorrisApp());

class NineMensMorrisApp extends StatelessWidget {
  const NineMensMorrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Nine Mens Morris',
      tagline: 'An ancient duel of mills and mischief. Outsmart, outplace, outlast! 🏰',
      emoji: '🏰',
      slug: 'ninemensmorris',
      howToPlay:
          '• Phase 1 — PLACE: take turns dropping your 9 knights on empty spots.\n• Phase 2 — MOVE: slide one knight along a line to a free spot.\n• Down to 3 knights? You FLY — jump to any free spot!\n• Make a MILL (3 in a row) to capture an enemy knight. 💥\n• Win by leaving your rival with 2 knights — or zero moves. 🏆',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => NineMensMorrisScreen(players: players, callbacks: cb),
    );
  }
}
