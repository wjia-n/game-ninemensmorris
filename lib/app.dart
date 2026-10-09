/// App shell: splash → menu, routes, theme, lifecycle handling
/// (auto-pause + save on backgrounding; audio pause/resume).
library;

import 'package:flutter/material.dart';

import 'audio/sound.dart';
import 'services/iap_service.dart';
import 'state/game_controller.dart';
import 'ui/lapidary.dart';
import 'ui/screens/customize_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/gameover_screen.dart';
import 'ui/screens/howto_screen.dart';
import 'ui/screens/menu_screen.dart';
import 'ui/screens/new_game_screen.dart';
import 'ui/screens/pro_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/splash_screen.dart';

class NineMensMorrisApp extends StatefulWidget {
  const NineMensMorrisApp({super.key});

  @override
  State<NineMensMorrisApp> createState() => _NineMensMorrisAppState();
}

class _NineMensMorrisAppState extends State<NineMensMorrisApp>
    with WidgetsBindingObserver {
  late final GameController _controller;
  late final StoreService _store;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = GameController();
    _store = StoreService();
    _boot();
  }

  Future<void> _boot() async {
    // Settings/stats/sound/store are initialized inside the splash flow
    // (which prewarms audio while the loading line animates). This just
    // waits for the splash to hand control back.
  }

  void _onSplashDone() {
    if (!mounted) return;
    setState(() => _ready = true);
    Sound.I.menuMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _store.dispose();
    Sound.I.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding: pause the duel and persist it (RULES.md §12.10),
    // and freeze audio in place so it resumes exactly where it left off.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      Sound.I.onLifecycleResume();
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
          ? MenuScreen(controller: _controller, store: _store)
          : SplashScreen(store: _store, onDone: _onSplashDone),
      routes: {
        '/new': (_) => NewGameScreen(controller: _controller),
        '/game': (_) => GameScreen(controller: _controller),
        '/gameover': (_) => GameOverScreen(controller: _controller),
        '/settings': (_) => const SettingsScreen(),
        '/howto': (_) => const HowToScreen(),
        '/pro': (_) => ProScreen(store: _store),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/customize') {
          return MaterialPageRoute(
            builder: (_) => CustomizeScreen(
              onOpenPro: () => Navigator.of(context).pushNamed('/pro'),
            ),
          );
        }
        return null;
      },
    );
  }
}
