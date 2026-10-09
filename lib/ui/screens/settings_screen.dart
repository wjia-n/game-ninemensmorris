/// Settings: SETTINGS cartouche, parchment panel with stone toggles
/// (music, SFX), carved sliders (volumes), difficulty tablets, human-first
/// toggle, reset statistics, BACK — per the Stitch settings screen.
library;

import 'package:flutter/material.dart';

import '../../audio/sound.dart';
import '../../engine/ai.dart';
import '../../state/settings.dart';
import '../../state/stats.dart';
import '../lapidary.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsStore.I;
    return Scaffold(
      body: VaultBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedBuilder(
                animation: s,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Cartouche(
                        title: 'SETTINGS', subtitle: 'ORDO · AVDIO · BOARD'),
                    const SizedBox(height: 16),
                    ParchmentPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _row('Music', StoneToggle(
                            value: s.musicOn,
                            onChanged: (v) async {
                              await s.setMusic(v);
                              if (v) {
                                Sound.I.menuMusic();
                              } else {
                                Sound.I.stopMusic();
                              }
                            },
                          )),
                          const SizedBox(height: 10),
                          _row('Sound effects', StoneToggle(
                            value: s.sfxOn,
                            onChanged: (v) async {
                              await s.setSfx(v);
                              if (v) Sound.I.click();
                            },
                          )),
                          const SizedBox(height: 14),
                          _label('Music volume'),
                          CarvedSlider(
                            value: s.musicVolume,
                            onChanged: s.setMusicVolume,
                          ),
                          const SizedBox(height: 8),
                          _label('Effects volume'),
                          CarvedSlider(
                            value: s.sfxVolume,
                            onChanged: (v) async {
                              await s.setSfxVolume(v);
                              Sound.I.click();
                            },
                          ),
                          const SizedBox(height: 14),
                          const EngravedDivider(),
                          _label('Difficulty'),
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
                                      selected: s.difficulty == d,
                                      onTap: () => s.setDifficulty(d),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _row('You move first (vs AI)', StoneToggle(
                            value: s.humanFirst,
                            onChanged: s.setHumanFirst,
                          )),
                          const SizedBox(height: 14),
                          const EngravedDivider(),
                          BronzeTablet(
                            label: 'RESET STATISTICS',
                            fontSize: 14,
                            onTap: () => StatsStore.I.reset(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    BronzeTablet(
                      label: 'BACK',
                      fontSize: 16,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, Widget control) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Lapidary.letterpress(15))),
        control,
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text,
          style: Lapidary.letterpress(13, weight: FontWeight.bold)),
    );
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
