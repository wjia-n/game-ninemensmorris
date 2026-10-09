/// App shell: routes, theme, lifecycle handling (auto-pause + save on
/// backgrounding) for Nine Men's Morris.
library;

import 'package:flutter/material.dart';

import 'audio/sound.dart';
import 'state/game_controller.dart';
import 'state/settings.dart';
import 'state/stats.dart';
import 'ui/lapidary.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/gameover_screen.dart';
import 'ui/screens/howto_screen.dart';
import 'ui/screens/menu_screen.dart';
import 'ui/screens/new_game_screen.dart';
import 'ui/screens/settings_screen.dart';

class NineMensMorrisApp extends StatefulWidget {
  const NineMensMorrisApp({super.key});

  @override
  State<NineMensMorrisApp> createState() => _NineMensMorrisAppState();
}

class _NineMensMorrisAppState extends State<NineMensMorrisApp>
    with WidgetsBindingObserver {
  late final GameController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = GameController();
    _boot();
  }

  Future<void> _boot() async {
    await SettingsStore.I.init();
    await StatsStore.I.init();
    await Sound.I.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    Sound.I.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding: pause the duel and persist it (RULES.md §12.10).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nine Men's Morris",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Lapidary.basaltDeep,
        fontFamily: Lapidary.serif,
        colorScheme: const ColorScheme.dark(
          primary: Lapidary.bronzeLight,
          secondary: Lapidary.verdigris,
          surface: Lapidary.basalt,
        ),
      ),
      home: _ready
          ? MenuScreen(controller: _controller)
          : const Scaffold(
              backgroundColor: Lapidary.basaltDeep,
              body: Center(
                child: CircularProgressIndicator(
                    color: Lapidary.bronzeLight),
              ),
            ),
      routes: {
        '/new': (_) => NewGameScreen(controller: _controller),
        '/game': (_) => GameScreen(controller: _controller),
        '/gameover': (_) => GameOverScreen(controller: _controller),
        '/settings': (_) => const SettingsScreen(),
        '/howto': (_) => const HowToScreen(),
      },
    );
  }
}
