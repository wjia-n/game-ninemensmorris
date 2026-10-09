/// Main menu: chiseled title cartouche, decorative board vignette, bronze
/// tablets (New Game / Continue / How to Play / Settings), stats chips and a
/// parchment flavor strip — matching the Stitch menu screen.
library;

import 'package:flutter/material.dart';

import '../../audio/sound.dart';
import '../../state/game_controller.dart';
import '../../state/stats.dart';
import '../board_painter.dart';
import '../lapidary.dart';
import '../widgets.dart';

class MenuScreen extends StatefulWidget {
  final GameController controller;
  const MenuScreen({super.key, required this.controller});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
    Sound.I.menuMusic();
    widget.controller.hasSavedGame().then((v) {
      if (mounted) setState(() => _hasSave = v);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = StatsStore.I;
    return Scaffold(
      body: VaultBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Cartouche(
                    title: "NINE MEN'S\nMORRIS",
                    subtitle: 'MOLA · ROTUNDA · TABVLA ANTIQVA',
                    fontSize: 34,
                  ),
                  const SizedBox(height: 14),
                  // Decorative board vignette.
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => CustomPaint(
                          painter: BoardPainter.decorative(pulse: _pulse.value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_hasSave)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BronzeTablet(
                        label: 'CONTINUE',
                        sublabel: 'RESUME THE UNFINISHED DUEL',
                        onTap: () async {
                          if (await widget.controller.continueSaved()) {
                            if (context.mounted) {
                              Navigator.of(context).pushNamed('/game');
                            }
                          }
                        },
                      ),
                    ),
                  BronzeTablet(
                    label: 'NEW GAME',
                    sublabel: 'CHALLENGE THE STONE MIND',
                    onTap: () => Navigator.of(context).pushNamed('/new'),
                  ),
                  const SizedBox(height: 10),
                  BronzeTablet(
                    label: 'HOW TO PLAY',
                    sublabel: 'LEARN THE ANCIENT RULES',
                    fontSize: 16,
                    onTap: () => Navigator.of(context).pushNamed('/howto'),
                  ),
                  const SizedBox(height: 10),
                  BronzeTablet(
                    label: 'SETTINGS',
                    sublabel: 'SOUND · MUSIC · DIFFICULTY',
                    fontSize: 16,
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                  const SizedBox(height: 16),
                  if (stats.gamesPlayed > 0)
                    ParchmentPanel(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stat('${stats.wins}', 'WINS'),
                          const SizedBox(width: 18),
                          _stat('${stats.losses}', 'LOSSES'),
                          const SizedBox(width: 18),
                          _stat('${stats.draws}', 'DRAWS'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  ParchmentPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Text(
                      'An ancient duel of mills and cunning — Roman soldiers '
                      'carved these lines into temple stone.',
                      textAlign: TextAlign.center,
                      style: Lapidary.body(13,
                          color: Lapidary.sepiaInk.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: Lapidary.letterpress(20)),
        Text(label,
            style: Lapidary.letterpress(10, weight: FontWeight.bold)),
      ],
    );
  }
}
