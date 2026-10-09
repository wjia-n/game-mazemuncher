import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/maze_craft.dart';
import '../theme/maze_themes.dart';

/// Settings: renameable player profile, audio controls, lifetime stats.
class SettingsScreen extends StatefulWidget {
  final MazeAudio audio;
  final MazeSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus;

  MazeThemeDef get _t => MazeThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.settings.playerName);
    _nameFocus = FocusNode();
    // Commit the current text when the field loses focus.
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        widget.settings.setPlayerName(_nameCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    // Commit any pending keystrokes before the screen goes away.
    widget.settings.setPlayerName(_nameCtrl.text);
    _nameFocus.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
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
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: MazeCraft.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLAYER', style: MazeCraft.label(13, theme: t)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.panel.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: t.accent.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      maxLength: 16,
                      style: MazeCraft.body(17, theme: t),
                      // Save on EVERY keystroke — never lose a name.
                      onChanged: s.setPlayerName,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: 'Your muncher name',
                        hintStyle: MazeCraft.body(15,
                            theme: t, color: t.textDim),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.check, color: t.accentLight),
                          onPressed: () {
                            widget.audio.click();
                            s.setPlayerName(_nameCtrl.text);
                            FocusScope.of(context).unfocus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Name saved!',
                                    style: MazeCraft.body(14, theme: t)),
                                backgroundColor: t.panel,
                                behavior: SnackBarBehavior.floating,
                                duration:
                                    const Duration(milliseconds: 1200),
                              ),
                            );
                          },
                        ),
                      ),
                      onSubmitted: (v) {
                        widget.audio.click();
                        s.setPlayerName(v);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('AUDIO', style: MazeCraft.label(13, theme: t)),
                  const SizedBox(height: 8),
                  SettingRow(
                    theme: t,
                    label: 'Music',
                    control: CraftToggle(
                      theme: t,
                      value: s.musicOn,
                      onChanged: (v) {
                        widget.audio.click();
                        s.setMusic(v);
                        _applyAudio();
                      },
                    ),
                  ),
                  SettingRow(
                    theme: t,
                    label: 'Sound effects',
                    control: CraftToggle(
                      theme: t,
                      value: s.sfxOn,
                      onChanged: (v) {
                        widget.audio.click();
                        s.setSfx(v);
                        _applyAudio();
                      },
                    ),
                  ),
                  SettingRow(
                    theme: t,
                    label: 'Volume',
                    control: SizedBox(
                      width: 170,
                      child: BeadSlider(
                        theme: t,
                        value: s.volume,
                        onChanged: (v) {
                          s.setVolume(v);
                          _applyAudio();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('LIFETIME STATS', style: MazeCraft.label(13, theme: t)),
                  const SizedBox(height: 8),
                  _StatsCard(theme: t, settings: s),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final MazeThemeDef theme;
  final MazeSettings settings;
  const _StatsCard({required this.theme, required this.settings});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final rows = [
      ('Games played', '${s.gamesPlayed}'),
      ('Campaigns completed', '${s.campaignsCompleted}'),
      ('Campaign progress', '${s.campaignLevel}/9 mazes'),
      ('Endless best', '${s.endlessBest}'),
      ('Score Attack best', '${s.attackBest}'),
      ('Pellets munched', '${s.totalPellets}'),
      ('Ghosts munched', '${s.totalGhosts}'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: theme.panel.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                      child: Text(r.$1,
                          style: MazeCraft.body(14, theme: theme))),
                  Text(r.$2,
                      style: MazeCraft.label(14, theme: theme)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
