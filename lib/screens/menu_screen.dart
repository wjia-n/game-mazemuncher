import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/maze_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/maze_craft.dart';
import '../theme/maze_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';

const storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.mazemuncher';

const difficultyNames = ['Chill', 'Classic', 'Nightmare'];
const difficultyBlurbs = [
  'Slower ghosts, 4 lives — learn the maze',
  'The true arcade chase',
  'Relentless ghosts, 3 lives — PRO',
];

/// Main menu: logo, best scores, mode + difficulty pickers, themes,
/// settings, Pro, how-to-play, share, rate.
class MenuScreen extends StatelessWidget {
  final MazeAudio audio;
  final MazeSettings settings;
  final StoreService store;
  const MenuScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  MazeThemeDef get _t => MazeThemes.byId(settings.themeId,
      custom: settings.customTheme);

  void _play(BuildContext context) {
    audio.click();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModeSheet(
          audio: audio, settings: settings, store: store, theme: _t),
    );
  }

  void _open(BuildContext context, Widget page) {
    audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _share() async {
    audio.click();
    try {
      await Share.share(
          'I\'m munching mazes in Maze Muncher! Can you beat my score? $storeUrl');
    } catch (_) {}
  }

  Future<void> _rate() async {
    audio.click();
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
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
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/mazemuncher_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Maze Muncher',
                      style: MazeCraft.display(40, theme: t),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Gobble every pellet. Dodge the ghosts.',
                      style: MazeCraft.body(15, theme: t, color: t.textDim),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  _ScoreStrip(theme: t, settings: settings),
                  const SizedBox(height: 22),
                  MunchButton(
                      label: 'PLAY',
                      icon: Icons.play_arrow,
                      theme: t,
                      width: 260,
                      fontSize: 22,
                      onTap: () => _play(context)),
                  const SizedBox(height: 12),
                  _DifficultyRow(
                      theme: t,
                      settings: settings,
                      audio: audio,
                      store: store),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _MenuChip(
                          theme: t,
                          icon: Icons.palette,
                          label: 'Themes',
                          onTap: () => _open(
                              context,
                              ThemeScreen(
                                  audio: audio,
                                  settings: settings,
                                  store: store))),
                      _MenuChip(
                          theme: t,
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () => _open(
                              context,
                              SettingsScreen(
                                  audio: audio, settings: settings))),
                      _MenuChip(
                          theme: t,
                          icon: settings.isPro
                              ? Icons.verified
                              : Icons.workspace_premium,
                          label: settings.isPro ? 'PRO ✓' : 'Go PRO',
                          onTap: () => _open(
                              context,
                              ProScreen(
                                  audio: audio,
                                  settings: settings,
                                  store: store))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IconAction(
                          theme: t,
                          icon: Icons.help_outline,
                          label: 'How to play',
                          onTap: () => _showHowTo(context, t)),
                      _IconAction(
                          theme: t,
                          icon: Icons.share,
                          label: 'Share',
                          onTap: _share),
                      _IconAction(
                          theme: t,
                          icon: Icons.star_outline,
                          label: 'Rate',
                          onTap: _rate),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: MazeCraft.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, MazeThemeDef t) {
    audio.click();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('How to play', style: MazeCraft.display(22, theme: t)),
        content: SingleChildScrollView(
          child: Text(
            '• SWIPE to steer your muncher through the maze.\n\n'
            '• Gobble every pellet to clear the maze.\n\n'
            '• Big glowing pellets turn the tables — hunt the blue ghosts for 200 → 400 → 800 → 1600 points!\n\n'
            '• Each ghost has its own personality: the red one chases you, the pink one cuts you off, the teal one is shy, the orange one wanders.\n\n'
            '• Grab the cherry bonus when it appears.\n\n'
            '• Extra life every 10,000 points.\n\n'
            'CAMPAIGN: clear 9 mazes to rule the maze.\n'
            'ENDLESS: infinite mazes, ghosts get faster.\n'
            'SCORE ATTACK: 120 seconds — clearing a maze adds 15s!',
            style: MazeCraft.body(14, theme: t),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
            child: Text('Got it!', style: MazeCraft.label(15, theme: t)),
          ),
        ],
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  final MazeThemeDef theme;
  final MazeSettings settings;
  const _ScoreStrip({required this.theme, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.panel.withValues(alpha: 0.8),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(theme, 'CAMPAIGN',
              '${settings.campaignLevel}/$campaignMazeCount mazes'),
          _Stat(theme, 'ENDLESS', '${settings.endlessBest}'),
          _Stat(theme, 'ATTACK', '${settings.attackBest}'),
        ],
      ),
    );
  }

  Widget _Stat(MazeThemeDef t, String k, String v) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: MazeCraft.label(10, theme: t, color: t.textDim)),
          const SizedBox(height: 2),
          Text(v, style: MazeCraft.body(14, theme: t)),
        ],
      );
}

class _DifficultyRow extends StatelessWidget {
  final MazeThemeDef theme;
  final MazeSettings settings;
  final MazeAudio audio;
  final StoreService store;
  const _DifficultyRow(
      {required this.theme,
      required this.settings,
      required this.audio,
      required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('DIFFICULTY', style: MazeCraft.label(12, theme: theme)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DiffChip(
                  theme: theme,
                  label: difficultyNames[i],
                  blurb: difficultyBlurbs[i],
                  selected: settings.difficulty == i,
                  locked: i == 2 && !settings.isPro,
                  onTap: () {
                    if (i == 2 && !settings.isPro) {
                      audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProScreen(
                              audio: audio,
                              settings: settings,
                              store: store)));
                      return;
                    }
                    audio.click();
                    settings.setDifficulty(i);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DiffChip extends StatelessWidget {
  final MazeThemeDef theme;
  final String label;
  final String blurb;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _DiffChip({
    required this.theme,
    required this.label,
    required this.blurb,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: blurb,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? theme.accent.withValues(alpha: 0.3)
                : theme.panel.withValues(alpha: 0.8),
            border: Border.all(
                color: selected ? theme.accent : theme.textDim.withValues(alpha: 0.3),
                width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.lock,
                      size: 14, color: theme.textDim),
                ),
              Text(label,
                  style: MazeCraft.label(13,
                      theme: theme,
                      color: selected ? theme.accentLight : theme.text)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  final MazeThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuChip(
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
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.panel.withValues(alpha: 0.85),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.accentLight, size: 20),
            const SizedBox(width: 8),
            Text(label, style: MazeCraft.label(15, theme: theme)),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final MazeThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _IconAction(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.panel,
                border: Border.all(color: theme.accent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 3),
                      blurRadius: 6),
                ],
              ),
              child: Icon(icon, color: theme.accentLight, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: MazeCraft.body(11, theme: theme, color: theme.textDim)),
          ],
        ),
      ),
    );
  }
}

/// Mode picker: campaign / endless / score attack.
class _ModeSheet extends StatelessWidget {
  final MazeAudio audio;
  final MazeSettings settings;
  final StoreService store;
  final MazeThemeDef theme;
  const _ModeSheet(
      {required this.audio,
      required this.settings,
      required this.store,
      required this.theme});

  void _start(BuildContext context, GameMode mode) {
    audio.click();
    settings.setLastMode(mode.index);
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GameScreen(
            audio: audio,
            settings: settings,
            store: store,
            mode: mode,
            difficulty: MazeDifficulty.values[settings.difficulty])));
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: t.accent, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: t.textDim.withValues(alpha: 0.5))),
          const SizedBox(height: 14),
          Text('Choose your chase', style: MazeCraft.display(22, theme: t)),
          const SizedBox(height: 14),
          _ModeCard(
              theme: t,
              icon: Icons.map,
              title: 'Campaign',
              desc:
                  'Clear 9 hand-built mazes, easiest to trickiest. Progress saves!',
              tag: settings.campaignLevel > 0
                  ? 'Maze ${settings.campaignLevel + 1} unlocked'
                  : 'Start at Maze 1',
              onTap: () => _start(context, GameMode.campaign)),
          const SizedBox(height: 10),
          _ModeCard(
              theme: t,
              icon: Icons.all_inclusive,
              title: 'Endless',
              desc:
                  'Infinite generated mazes. Ghosts get faster every maze. How deep can you go?',
              tag: settings.endlessBest > 0
                  ? 'Best: ${settings.endlessBest}'
                  : 'No record yet',
              onTap: () => _start(context, GameMode.endless)),
          const SizedBox(height: 10),
          _ModeCard(
              theme: t,
              icon: Icons.timer,
              title: 'Score Attack',
              desc:
                  '120 seconds on the clock. Clearing a maze adds +15s. Pure scoring!',
              tag: settings.attackBest > 0
                  ? 'Best: ${settings.attackBest}'
                  : 'No record yet',
              onTap: () => _start(context, GameMode.scoreAttack)),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final MazeThemeDef theme;
  final IconData icon;
  final String title;
  final String desc;
  final String tag;
  final VoidCallback onTap;
  const _ModeCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.desc,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.bg.withValues(alpha: 0.6),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  theme.accentLight,
                  theme.accent,
                  theme.accentDark
                ]),
              ),
              child: Icon(icon, color: theme.bg, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: MazeCraft.display(18, theme: theme)),
                      const SizedBox(width: 8),
                      Text(tag,
                          style: MazeCraft.body(11,
                              theme: theme, color: theme.textDim)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: MazeCraft.body(13,
                          theme: theme, color: theme.textDim)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.accentLight),
          ],
        ),
      ),
    );
  }
}
