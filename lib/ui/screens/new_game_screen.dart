/// New-game stele: mode (vs the Stone Mind / two players), difficulty
/// tablets, who moves first — then the great bronze START tablet.
library;

import 'package:flutter/material.dart';

import '../../engine/ai.dart';
import '../../state/game_controller.dart';
import '../../state/settings.dart';
import '../lapidary.dart';
import '../widgets.dart';

class NewGameScreen extends StatefulWidget {
  final GameController controller;
  const NewGameScreen({super.key, required this.controller});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  GameMode _mode = GameMode.vsAi;
  Difficulty _difficulty = Difficulty.medium;
  bool _humanFirst = true;

  @override
  void initState() {
    super.initState();
    _difficulty = SettingsStore.I.difficulty;
    _humanFirst = SettingsStore.I.humanFirst;
  }

  @override
  Widget build(BuildContext context) {
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
                      title: 'NEW GAME', subtitle: 'CHOOSE YOUR DUEL'),
                  const SizedBox(height: 16),
                  ParchmentPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _heading('ADVERSARY'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: BronzeTablet(
                                label: 'STONE MIND',
                                sublabel: 'VS THE ANCIENT AI',
                                fontSize: 14,
                                selected: _mode == GameMode.vsAi,
                                onTap: () =>
                                    setState(() => _mode = GameMode.vsAi),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: BronzeTablet(
                                label: 'TWO SOULS',
                                sublabel: 'PASS & PLAY',
                                fontSize: 14,
                                selected: _mode == GameMode.twoPlayer,
                                onTap: () => setState(
                                    () => _mode = GameMode.twoPlayer),
                              ),
                            ),
                          ],
                        ),
                        if (_mode == GameMode.vsAi) ...[
                          const SizedBox(height: 16),
                          _heading('DIFFICULTY'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final d in Difficulty.values)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: BronzeTablet(
                                      label: _diffLabel(d),
                                      fontSize: 13,
                                      selected: _difficulty == d,
                                      onTap: () {
                                        setState(() => _difficulty = d);
                                        SettingsStore.I.setDifficulty(d);
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text('You move first',
                                    style: Lapidary.letterpress(15)),
                              ),
                              StoneToggle(
                                value: _humanFirst,
                                onChanged: (v) {
                                  setState(() => _humanFirst = v);
                                  SettingsStore.I.setHumanFirst(v);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BronzeTablet(
                    label: 'BEGIN THE DUEL',
                    fontSize: 20,
                    onTap: () async {
                      await widget.controller.startNew(
                        mode: _mode,
                        difficulty: _difficulty,
                        humanSeat: _humanFirst ? 0 : 1,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/game');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  BronzeTablet(
                    label: 'BACK',
                    fontSize: 14,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) {
    return Text(text,
        style: Lapidary.letterpress(13, weight: FontWeight.bold));
  }

  String _diffLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'EASY';
      case Difficulty.medium:
        return 'MEDIUM';
      case Difficulty.hard:
        return 'HARD';
    }
  }
}
