/// How-to-play: a parchment scroll with the rules of the ancient game,
/// condensed from RULES.md.
library;

import 'package:flutter/material.dart';

import '../lapidary.dart';
import '../widgets.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

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
                      title: 'HOW TO PLAY',
                      subtitle: 'REGVLAE · FORM MILLS'),
                  const SizedBox(height: 16),
                  ParchmentPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _h('THE GOAL'),
                        _p('Command 9 bronze or bone men. Win by grinding your '
                            'rival down to 2 men — or by blocking them so they '
                            'have no legal move.'),
                        _h('PHASE 1 · PLACING'),
                        _p('Take turns setting one man on any empty point '
                            'until all 18 are placed.'),
                        _h('PHASE 2 · MOVING'),
                        _p('Slide one man along a carved line to an adjacent '
                            'empty point. No diagonals, no jumping.'),
                        _h('FLYING'),
                        _p('Reduced to exactly 3 men? You may fly — leap to '
                            'any empty point on the board.'),
                        _h('MILLS & CAPTURES'),
                        _p('Three of your men in a row along the lines forms '
                            'a mill. Each fresh mill lets you capture one '
                            'enemy man. Men inside mills are protected — '
                            'unless every enemy man sits in a mill.'),
                        _h('DRAWS'),
                        _p('The same position three times, or 50 plies with '
                            'no mill and no capture, ends the duel in a draw. '
                            'You may also offer a draw from the toolbar.'),
                        _h('STARS'),
                        _p('Beat the Stone Mind with 5+ men left for 3 stars, '
                            '3–4 men for 2 stars, any other win for 1 star.'),
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
    );
  }

  Widget _h(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text,
            style: Lapidary.letterpress(14, weight: FontWeight.bold)),
      );

  Widget _p(String text) => Text(text, style: Lapidary.body(13.5));
}
