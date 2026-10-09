import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'theme/maze_craft.dart';
import 'theme/maze_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = MazeSettings();
  await settings.load();
  final audio = MazeAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  final store = StoreService();
  // Store init is fire-and-forget: the Pro screen reads store state lazily.
  store.init();
  runApp(MazeMuncherApp(settings: settings, audio: audio, store: store));
}

class MazeMuncherApp extends StatefulWidget {
  final MazeSettings settings;
  final MazeAudio audio;
  final StoreService store;
  const MazeMuncherApp(
      {super.key,
      required this.settings,
      required this.audio,
      required this.store});

  @override
  State<MazeMuncherApp> createState() => _MazeMuncherAppState();
}

class _MazeMuncherAppState extends State<MazeMuncherApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the game screen additionally freezes its engine.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Maze Muncher',
        debugShowCheckedModeBanner: false,
        theme: MazeCraft.theme(MazeThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme)),
        home: SplashScreen(
            audio: widget.audio,
            settings: widget.settings,
            store: widget.store),
      ),
    );
  }
}
