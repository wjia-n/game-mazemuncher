import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/maze_craft.dart';
import '../theme/maze_themes.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';

/// Theme studio: maze themes, muncher characters, wall materials.
/// Pro-only items show a lock and open the Pro screen.
class ThemeScreen extends StatelessWidget {
  final MazeAudio audio;
  final MazeSettings settings;
  final StoreService store;
  const ThemeScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  MazeThemeDef get _t => MazeThemes.byId(settings.themeId,
      custom: settings.customTheme);

  void _goPro(BuildContext context) {
    audio.click();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ProScreen(audio: audio, settings: settings, store: store)));
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return MazeBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title:
              Text('Theme Studio', style: MazeCraft.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHead(
                      theme: t,
                      title: 'MAZE THEMES',
                      actionLabel: 'Create mine',
                      onAction: () {
                        if (!settings.isPro) {
                          _goPro(context);
                          return;
                        }
                        audio.click();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CustomThemeScreen(
                                audio: audio, settings: settings)));
                      }),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount:
                        MazeThemes.all.length + 1, // +1 = custom creator
                    itemBuilder: (_, i) {
                      if (i == MazeThemes.all.length) {
                        final locked = !settings.isPro;
                        final selected = settings.themeId == 'custom';
                        return _ThemeTile(
                          theme: t,
                          name: 'My Creation',
                          selected: selected,
                          locked: locked,
                          swatches: [
                            settings.customTheme.wallFace,
                            settings.customTheme.floor,
                            settings.customTheme.pellet,
                            settings.customTheme.accent,
                          ],
                          onTap: () {
                            if (locked) {
                              _goPro(context);
                              return;
                            }
                            audio.click();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => CustomThemeScreen(
                                    audio: audio, settings: settings)));
                          },
                        );
                      }
                      final th = MazeThemes.all[i];
                      final locked = !settings.isPro &&
                          MazeThemes.isProTheme(th.id);
                      return _ThemeTile(
                        theme: t,
                        name: th.name,
                        selected: settings.themeId == th.id,
                        locked: locked,
                        swatches: [
                          th.wallFace,
                          th.floor,
                          th.pellet,
                          th.accent
                        ],
                        onTap: () {
                          if (locked) {
                            _goPro(context);
                            return;
                          }
                          audio.click();
                          settings.setTheme(th.id);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _SectionHead(theme: t, title: 'MUNCHER CHARACTERS'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: MuncherStyles.names.length,
                    itemBuilder: (_, i) {
                      final locked =
                          !settings.isPro && MuncherStyles.isPro(i);
                      return _StyleTile(
                        theme: t,
                        name: MuncherStyles.names[i],
                        blurb: MuncherStyles.blurb[i],
                        selected: settings.muncherStyle == i,
                        locked: locked,
                        preview: _MuncherDot(
                            theme: t,
                            style: i,
                            muncher: t.muncher,
                            selected: settings.muncherStyle == i),
                        onTap: () {
                          if (locked) {
                            _goPro(context);
                            return;
                          }
                          audio.click();
                          settings.setMuncherStyle(i);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _SectionHead(theme: t, title: 'WALL MATERIALS'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: WallStyles.names.length,
                    itemBuilder: (_, i) {
                      final locked =
                          !settings.isPro && WallStyles.isPro(i);
                      return _StyleTile(
                        theme: t,
                        name: WallStyles.names[i],
                        blurb: WallStyles.blurb[i],
                        selected: settings.wallStyle == i,
                        locked: locked,
                        preview: _WallDot(
                            theme: t,
                            style: i,
                            selected: settings.wallStyle == i),
                        onTap: () {
                          if (locked) {
                            _goPro(context);
                            return;
                          }
                          audio.click();
                          settings.setWallStyle(i);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final MazeThemeDef theme;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHead(
      {required this.theme,
      required this.title,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: MazeCraft.label(13, theme: theme))),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.accent, width: 1.5),
              ),
              child: Text(actionLabel!,
                  style: MazeCraft.label(12, theme: theme)),
            ),
          ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final MazeThemeDef theme;
  final String name;
  final bool selected;
  final bool locked;
  final List<Color> swatches;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.theme,
    required this.name,
    required this.selected,
    required this.locked,
    required this.swatches,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: t.panel.withValues(alpha: 0.85),
          border: Border.all(
              color: selected ? t.accentLight : t.textDim.withValues(alpha: 0.3),
              width: selected ? 2.5 : 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: t.accent.withValues(alpha: 0.35),
                      blurRadius: 10)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final c in swatches)
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.4)),
                    ),
                  ),
                const Spacer(),
                if (locked)
                  Icon(Icons.lock, size: 16, color: t.textDim),
                if (selected)
                  Icon(Icons.check_circle,
                      size: 18, color: t.accentLight),
              ],
            ),
            const Spacer(),
            Text(name,
                style: MazeCraft.body(13, theme: t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  final MazeThemeDef theme;
  final String name;
  final String blurb;
  final bool selected;
  final bool locked;
  final Widget preview;
  final VoidCallback onTap;
  const _StyleTile({
    required this.theme,
    required this.name,
    required this.blurb,
    required this.selected,
    required this.locked,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Tooltip(
      message: blurb,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: t.panel.withValues(alpha: 0.85),
            border: Border.all(
                color:
                    selected ? t.accentLight : t.textDim.withValues(alpha: 0.3),
                width: selected ? 2.5 : 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  preview,
                  if (locked)
                    const Icon(Icons.lock,
                        size: 18, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 6),
              Text(name,
                  style: MazeCraft.body(10, theme: t),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live muncher preview dot (mini version of the painter's character).
class _MuncherDot extends StatelessWidget {
  final MazeThemeDef theme;
  final int style;
  final Color muncher;
  final bool selected;
  const _MuncherDot(
      {required this.theme,
      required this.style,
      required this.muncher,
      required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: style == 1 ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: style == 1 ? BorderRadius.circular(10) : null,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [Colors.white.withValues(alpha: 0.4), muncher, t.bg],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
            color: selected ? t.accentLight : Colors.black45, width: 2),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white),
          child: const Center(
            child: SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Live wall-material preview dot.
class _WallDot extends StatelessWidget {
  final MazeThemeDef theme;
  final int style;
  final bool selected;
  const _WallDot(
      {required this.theme, required this.style, required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: t.wallDark,
        border: Border.all(
            color: selected ? t.accentLight : Colors.black45, width: 2),
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: t.wallFace,
            border: Border.all(
                color: t.wallLight.withValues(alpha: 0.8), width: 2),
          ),
          child: Center(
            child: Text(_glyph(style),
                style: TextStyle(fontSize: 13, color: t.wallLight)),
          ),
        ),
      ),
    );
  }

  String _glyph(int s) => switch (s) {
        0 => '▤',
        1 => '▦',
        2 => '☰',
        3 => '🍬',
        4 => '🎋',
        5 => '◈',
        6 => '⚙',
        _ => '❧',
      };
}
