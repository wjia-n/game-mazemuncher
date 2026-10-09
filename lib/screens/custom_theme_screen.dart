import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/maze_craft.dart';
import '../theme/maze_themes.dart';

/// Custom theme creator (PRO): pick the physical colors of your own maze.
class CustomThemeScreen extends StatelessWidget {
  final MazeAudio audio;
  final MazeSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  MazeThemeDef get _t => MazeThemes.byId(settings.themeId,
      custom: settings.customTheme);

  static const _fields = [
    ('wallFace', 'Wall face'),
    ('wallLight', 'Wall highlight'),
    ('wallDark', 'Wall shadow'),
    ('floor', 'Floor'),
    ('pellet', 'Pellets'),
    ('powerPellet', 'Power pellets'),
    ('muncher', 'Muncher'),
    ('accent', 'Accent'),
  ];

  static const _palette = [
    0xFFF59E2C, 0xFFE8B93E, 0xFFFFD968, 0xFFD94F3D, 0xFFE88BB0, 0xFF4FA8C9,
    0xFF2E3D5C, 0xFF5B719E, 0xFF141B2E, 0xFF0E1424, 0xFFC89B62, 0xFF7A5230,
    0xFF2F6B52, 0xFF14382A, 0xFFB87333, 0xFF6E3E1A, 0xFF7C8494, 0xFF3E4452,
    0xFFE89BC0, 0xFF9E5B7D, 0xFFF5EFE0, 0xFF2A2118, 0xFF8FD48F, 0xFF2F6B4A,
  ];

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
              Text('My Creation', style: MazeCraft.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                audio.click();
                settings.resetCustomColors();
              },
              child:
                  Text('Reset', style: MazeCraft.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  // Live preview strip.
                  Container(
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: settings.customTheme.floor,
                      border: Border.all(color: t.accent, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _previewWall(settings.customTheme),
                        _previewPellet(settings.customTheme),
                        _previewMuncher(settings.customTheme),
                        _previewAccent(settings.customTheme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  MunchButton(
                    label: 'Use this theme',
                    icon: Icons.check,
                    theme: t,
                    width: 240,
                    fontSize: 17,
                    onTap: () {
                      audio.click();
                      settings.setTheme('custom');
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 14),
                  for (final f in _fields)
                    _ColorRow(
                      theme: t,
                      label: f.$2,
                      value: Color(settings.customColors[f.$1]!),
                      onPick: (c) {
                        audio.click();
                        settings.setCustomColor(f.$1, c.toARGB32());
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewWall(MazeThemeDef c) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: c.wallDark,
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: c.wallFace,
              border: Border.all(color: c.wallLight, width: 2),
            ),
          ),
        ),
      );

  Widget _previewPellet(MazeThemeDef c) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.pellet,
          boxShadow: const [
            BoxShadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3)
          ],
        ),
      );

  Widget _previewMuncher(MazeThemeDef c) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 1.1,
            colors: [Colors.white.withValues(alpha: 0.4), c.muncher],
          ),
          border: Border.all(color: Colors.black45, width: 2),
        ),
      );

  Widget _previewAccent(MazeThemeDef c) => Container(
        width: 46,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: [c.accentLight, c.accent]),
        ),
      );
}

class _ColorRow extends StatelessWidget {
  final MazeThemeDef theme;
  final String label;
  final Color value;
  final ValueChanged<Color> onPick;
  const _ColorRow(
      {required this.theme,
      required this.label,
      required this.value,
      required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.panel.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label, style: MazeCraft.body(15, theme: t))),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: value,
                  borderRadius: BorderRadius.circular(9),
                  border:
                      Border.all(color: t.accentLight, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in CustomThemeScreen._palette)
                GestureDetector(
                  onTap: () => onPick(Color(c)),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: value.toARGB32() == c
                              ? t.accentLight
                              : Colors.black45,
                          width: value.toARGB32() == c ? 3 : 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
