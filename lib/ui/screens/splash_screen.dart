/// Splash flow (MASTER_RULES branding): WAJIHA company splash using the
/// official winged-W logo (copied untouched), then the game splash — game
/// logo + name + animated loading line + "Credits: WAJIHA".
/// Audio is prewarmed and the store initialized while the line animates.
library;

import 'package:flutter/material.dart';

import '../../audio/sound.dart';
import '../../services/iap_service.dart';
import '../../state/settings.dart';
import '../../state/stats.dart';
import '../lapidary.dart';

class SplashScreen extends StatefulWidget {
  final StoreService store;
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.store, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _line;
  bool _companyPhase = true;

  @override
  void initState() {
    super.initState();
    _line = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _boot();
  }

  Future<void> _boot() async {
    // Company splash beat: the untouched WAJIHA mark.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _companyPhase = false);
    _line.forward();
    // Heavy lifting while the loading line animates.
    await SettingsStore.I.init();
    await StatsStore.I.init();
    await Sound.I.init();
    Sound.I.prewarm();
    try {
      await widget.store.init().timeout(const Duration(seconds: 6));
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Lapidary.basaltDeep,
      body: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: _companyPhase ? _companySplash() : _gameSplash(),
          ),
        ),
      ),
    );
  }

  Widget _companySplash() {
    return Column(
      key: const ValueKey('company'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset('assets/wajiha_logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 18),
        Text('WAJIHA',
            style: Lapidary.letterpress(26, weight: FontWeight.bold)
                .copyWith(color: Lapidary.parchment)),
      ],
    );
  }

  Widget _gameSplash() {
    return AnimatedBuilder(
      key: const ValueKey('game'),
      animation: _line,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/ninemensmorris_logo.png',
                fit: BoxFit.cover),
          ),
          const SizedBox(height: 22),
          Text("NINE MEN'S MORRIS",
              textAlign: TextAlign.center,
              style: Lapidary.letterpress(30, weight: FontWeight.bold)
                  .copyWith(color: Lapidary.parchment)),
          const SizedBox(height: 6),
          Text('An ancient duel of stone and bronze',
              style: Lapidary.body(14,
                  color: Lapidary.parchment.withValues(alpha: 0.7))),
          const SizedBox(height: 28),
          SizedBox(
            width: 210,
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Lapidary.umber,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                        color: Lapidary.bronzeDark.withValues(alpha: 0.6)),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _line.value.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Lapidary.bronzeLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Credits: WAJIHA',
                    style: Lapidary.body(12,
                        color:
                            Lapidary.parchment.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
