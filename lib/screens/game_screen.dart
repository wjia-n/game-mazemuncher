import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/maze_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/maze_craft.dart';
import '../theme/maze_painters.dart';
import '../theme/maze_themes.dart';
import 'menu_screen.dart' show storeUrl;

/// Gameplay screen: the engine owns all state and phases; this widget only
/// renders, forwards swipes, and plays sounds via [MazeEngine.onEvent].
class GameScreen extends StatefulWidget {
  final MazeAudio audio;
  final MazeSettings settings;
  final StoreService store;
  final GameMode mode;
  final MazeDifficulty difficulty;
  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.mode,
    required this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final MazeEngine _engine;
  bool _recorded = false;
  bool _reviewAsked = false;
  bool _menuPaused = false; // user paused from the pause button
  int _mazeId = 0;

  MazeThemeDef get _t => MazeThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = MazeEngine();
    _engine.onEvent = _onEvent;
    widget.audio.startGameMusic();
    // Let the first frame paint before the countdown begins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _engine.startRun(mode: widget.mode, difficulty: widget.difficulty);
      }
    });
  }

  void _onEvent(MazeEvent e) {
    final a = widget.audio;
    switch (e) {
      case MazeEvent.gameStart:
        a.gameStart();
        break;
      case MazeEvent.munch:
        a.munch();
        break;
      case MazeEvent.power:
        a.powerPellet();
        break;
      case MazeEvent.eatGhost:
        a.eatGhost();
        break;
      case MazeEvent.fruit:
        a.fruit();
        break;
      case MazeEvent.death:
        a.death();
        break;
      case MazeEvent.extraLife:
        a.extraLife();
        break;
      case MazeEvent.levelClear:
        a.levelClear();
        _mazeId++;
        break;
      case MazeEvent.gameOver:
        a.lose();
        _finishRun();
        break;
      case MazeEvent.victory:
        a.win();
        _finishRun();
        break;
      case MazeEvent.invalid:
        a.invalid();
    }
    if (mounted) setState(() {});
  }

  /// Record stats exactly once when the run reaches a terminal phase.
  void _finishRun() {
    if (_recorded) return;
    _recorded = true;
    final s = widget.settings;
    s.recordRun(
      mode: widget.mode.index,
      score: _engine.score,
      pellets: _engine.pelletsEatenRun,
      ghosts: _engine.ghostsEatenRun,
      completedCampaign: _engine.phase == MazePhase.victory,
      reachedLevel: _engine.mazeNumber,
    );
    if (_engine.phase == MazePhase.victory) _maybeReview();
    HapticFeedback.mediumImpact();
  }

  Future<void> _maybeReview() async {
    if (_reviewAsked) return;
    _reviewAsked = true;
    try {
      final review = InAppReview.instance;
      // Graceful when not installed from Play: isAvailable() is false.
      if (await review.isAvailable()) {
        await Future.delayed(const Duration(seconds: 1));
        await review.requestReview();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      // Never auto-resume a user-initiated pause — the pause overlay owns it.
      if (!_menuPaused) _engine.setPaused(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.dispose();
    widget.audio.startMenuMusic();
    super.dispose();
  }

  void _togglePause() {
    widget.audio.click();
    if (_engine.phase == MazePhase.playing ||
        _engine.phase == MazePhase.countdown) {
      _menuPaused = true;
      _engine.setPaused(true);
      widget.audio.onAppPaused();
      setState(() {});
    }
  }

  void _resume() {
    widget.audio.click();
    _menuPaused = false;
    widget.audio.onAppResumed();
    _engine.setPaused(false);
    setState(() {});
  }

  void _restart() {
    widget.audio.click();
    _menuPaused = false;
    widget.audio.onAppResumed();
    _recorded = false;
    _mazeId++;
    _engine.setPaused(false);
    _engine.restartRun();
    setState(() {});
  }

  void _quit() {
    widget.audio.click();
    _menuPaused = false;
    widget.audio.onAppResumed();
    _engine.quitToMenu();
    Navigator.of(context).pop();
  }

  Future<void> _shareScore() async {
    widget.audio.click();
    final won = _engine.phase == MazePhase.victory;
    try {
      await Share.share(won
          ? 'I RULED THE MAZE in Maze Muncher with ${_engine.score} points! Can you? $storeUrl'
          : 'I scored ${_engine.score} in Maze Muncher! Beat me if you can: $storeUrl');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return MazeBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _engine,
            builder: (_, _) => Stack(
              children: [
                Column(
                  children: [
                    _Hud(
                      theme: t,
                      engine: _engine,
                      playerName: widget.settings.playerName,
                      onPause: _togglePause,
                    ),
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (_, constraints) {
                            final cell = min(
                                constraints.maxWidth / _engine.w,
                                constraints.maxHeight / _engine.h);
                            final size = Size(
                                (_engine.w * cell).floorToDouble(),
                                (_engine.h * cell).floorToDouble());
                            return GestureDetector(
                              onHorizontalDragEnd: (d) {
                                final v = d.velocity.pixelsPerSecond.dx;
                                if (v.abs() > 120) {
                                  _engine.steer(Point(v > 0 ? 1 : -1, 0));
                                }
                              },
                              onVerticalDragEnd: (d) {
                                final v = d.velocity.pixelsPerSecond.dy;
                                if (v.abs() > 120) {
                                  _engine.steer(Point(0, v > 0 ? 1 : -1));
                                }
                              },
                              child: Container(
                                width: size.width,
                                height: size.height,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: t.accent.withValues(alpha: 0.5),
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.6),
                                        offset: const Offset(0, 8),
                                        blurRadius: 20),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SizedBox.fromSize(
                                  size: size,
                                  child: Stack(
                                    children: [
                                      RepaintBoundary(
                                        child: CustomPaint(
                                          size: size,
                                          painter: MazeStaticPainter(
                                            engine: _engine,
                                            theme: t,
                                            wallStyle:
                                                widget.settings.wallStyle,
                                            mazeId: _mazeId,
                                          ),
                                        ),
                                      ),
                                      CustomPaint(
                                        size: size,
                                        painter: MazeDynamicPainter(
                                          engine: _engine,
                                          theme: t,
                                          muncherStyle:
                                              widget.settings.muncherStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 6),
                      child: Text(
                        _engine.phase == MazePhase.playing
                            ? 'Swipe to steer'
                            : _hintFor(_engine.phase),
                        style: MazeCraft.body(12,
                            theme: t, color: t.textDim),
                      ),
                    ),
                  ],
                ),
                // Banner overlay.
                if (_engine.bannerT > 0 && _engine.banner.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withValues(alpha: 0.72),
                            border: Border.all(color: t.accent, width: 2),
                          ),
                          child: Text(_engine.banner,
                              style: MazeCraft.display(26, theme: t),
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
                if (_engine.paused) _PauseOverlay(theme: t, onResume: _resume, onRestart: _restart, onQuit: _quit),
                if (_engine.isTerminal)
                  _EndOverlay(
                    theme: t,
                    engine: _engine,
                    settings: widget.settings,
                    onRetry: _restart,
                    onQuit: _quit,
                    onShare: _shareScore,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _hintFor(MazePhase p) => switch (p) {
        MazePhase.countdown => 'Get ready…',
        MazePhase.dying => 'Ouch!',
        MazePhase.levelClear => 'Maze clear!',
        MazePhase.gameOver => 'Game over',
        MazePhase.victory => 'You win!',
        _ => '',
      };
}

class _Hud extends StatelessWidget {
  final MazeThemeDef theme;
  final MazeEngine engine;
  final String playerName;
  final VoidCallback onPause;
  const _Hud(
      {required this.theme,
      required this.engine,
      required this.playerName,
      required this.onPause});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(playerName,
                    style: MazeCraft.label(11, theme: t, color: t.textDim),
                    overflow: TextOverflow.ellipsis),
                Text('${engine.score}',
                    style: MazeCraft.display(24, theme: t)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: t.panel.withValues(alpha: 0.85),
              border: Border.all(
                  color: t.accent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Text(engine.hudLevel,
                style: MazeCraft.label(13, theme: t)),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < engine.lives.clamp(0, 9); i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.favorite,
                      color: t.ghostColors[0], size: 18),
                ),
            ],
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onPause,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.panel,
                border:
                    Border.all(color: t.accent.withValues(alpha: 0.5)),
              ),
              child: Icon(
                  engine.paused ? Icons.play_arrow : Icons.pause,
                  color: t.accentLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final MazeThemeDef theme;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  const _PauseOverlay(
      {required this.theme,
      required this.onResume,
      required this.onRestart,
      required this.onQuit});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: MazeCraft.display(36, theme: t)),
              const SizedBox(height: 24),
              MunchButton(
                  label: 'Resume', icon: Icons.play_arrow, theme: t, onTap: onResume),
              const SizedBox(height: 12),
              MunchButton(
                  label: 'Restart', icon: Icons.refresh, theme: t, onTap: onRestart),
              const SizedBox(height: 12),
              MunchButton(
                  label: 'Menu', icon: Icons.home, theme: t, onTap: onQuit),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndOverlay extends StatelessWidget {
  final MazeThemeDef theme;
  final MazeEngine engine;
  final MazeSettings settings;
  final VoidCallback onRetry;
  final VoidCallback onQuit;
  final VoidCallback onShare;
  const _EndOverlay({
    required this.theme,
    required this.engine,
    required this.settings,
    required this.onRetry,
    required this.onQuit,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final won = engine.phase == MazePhase.victory;
    final isBest = (engine.mode == GameMode.endless &&
            engine.score >= settings.endlessBest &&
            engine.score > 0) ||
        (engine.mode == GameMode.scoreAttack &&
            engine.score >= settings.attackBest &&
            engine.score > 0);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(won ? '🏆' : '👻',
                    style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 8),
                Text(
                    won
                        ? 'You rule the maze!'
                        : (engine.mode == GameMode.scoreAttack
                            ? "Time's up!"
                            : 'Game over'),
                    style: MazeCraft.display(32, theme: t),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: t.panel,
                    border: Border.all(color: t.accent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('SCORE',
                          style:
                              MazeCraft.label(12, theme: t, color: t.textDim)),
                      Text('${engine.score}',
                          style: MazeCraft.display(40, theme: t)),
                      if (isBest)
                        Text('★ NEW BEST! ★',
                            style: MazeCraft.label(14, theme: t)),
                      const SizedBox(height: 6),
                      Text(
                          '${engine.pelletsEatenRun} pellets · ${engine.ghostsEatenRun} ghosts munched',
                          style: MazeCraft.body(13,
                              theme: t, color: t.textDim)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                MunchButton(
                    label: won ? 'Play again' : 'Try again',
                    icon: Icons.refresh,
                    theme: t,
                    onTap: onRetry),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SmallBtn(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: onShare),
                    const SizedBox(width: 12),
                    _SmallBtn(
                        theme: t,
                        icon: Icons.home,
                        label: 'Menu',
                        onTap: onQuit),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final MazeThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.panel,
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.5), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.accentLight, size: 18),
            const SizedBox(width: 6),
            Text(label, style: MazeCraft.label(14, theme: theme)),
          ],
        ),
      ),
    );
  }
}
