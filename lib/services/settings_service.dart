import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/maze_themes.dart';

/// Persisted settings + stats for Maze Muncher. Survives app restarts.
///
/// Stores: audio toggles, player display name, theme/appearance choices
/// (incl. custom theme colors), difficulty + mode, Pro unlock state, and
/// lifetime stats (high scores per mode, campaign progress, totals).
class MazeSettings extends ChangeNotifier {
  static const _kMusic = 'mm_music_on';
  static const _kSfx = 'mm_sfx_on';
  static const _kVolume = 'mm_volume';
  static const _kDifficulty = 'mm_difficulty'; // 0 chill, 1 classic, 2 nightmare
  static const _kMode = 'mm_last_mode'; // 0 campaign, 1 endless, 2 attack
  static const _kNameLegacy = 'mm_player_name'; // legacy plain-string key
  static const _kNamesLegacy = 'mm_player_names'; // legacy unordered key
  static const _kNameJsonLegacy = 'mm_player_name_json'; // pre-release key

  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so
  /// ordered data must never use setStringList on Android. Even a single
  /// name is kept in one JSON string for consistency and safe migration.
  static const _kNameJson = 'mazemuncher_player_names_json';

  static const _kTheme = 'mm_theme_id';
  static const _kMuncher = 'mm_muncher_style';
  static const _kWall = 'mm_wall_style';
  static const _kCampaignLevel = 'mm_campaign_level'; // highest unlocked (0-based)
  static const _kEndlessBest = 'mm_endless_best';
  static const _kAttackBest = 'mm_attack_best';
  static const _kGames = 'mm_games_played';
  static const _kWins = 'mm_campaigns_completed';
  static const _kPellets = 'mm_total_pellets';
  static const _kGhosts = 'mm_total_ghosts';
  static const _kIsPro = 'mm_is_pro';
  static const _kCustomPrefix = 'mm_custom_';

  static const defaultName = 'Muncher';

  /// Encode the player name as one JSON string (order-preserving).
  static String encodePlayerName(String name) =>
      jsonEncode({'name': name.trim().isEmpty ? defaultName : name.trim()});

  /// Decode the persisted name; falls back to the default on missing/corrupt.
  static String decodePlayerName(String? raw) {
    if (raw == null) return defaultName;
    try {
      final d = jsonDecode(raw);
      if (d is Map && d['name'] is String) {
        final s = (d['name'] as String).trim();
        return s.isEmpty ? defaultName : s;
      }
    } catch (_) {}
    return defaultName;
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 1; // classic default
  int lastMode = 0; // campaign default
  String playerName = defaultName;
  String themeId = 'midnight';
  int muncherStyle = 0;
  int wallStyle = 0;
  int campaignLevel = 0; // highest campaign maze unlocked
  int endlessBest = 0;
  int attackBest = 0;
  int gamesPlayed = 0;
  int campaignsCompleted = 0;
  int totalPellets = 0;
  int totalGhosts = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints).
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'wallFace': 0xFF2E3D5C,
    'wallLight': 0xFF5B719E,
    'wallDark': 0xFF141B2E,
    'floor': 0xFF0E1424,
    'pellet': 0xFFE8C76A,
    'powerPellet': 0xFFFFD968,
    'muncher': 0xFFF59E2C,
    'accent': 0xFFE8B93E,
  };

  /// Builds the user-designed custom theme from stored colors.
  MazeThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return MazeThemeDef(
      id: 'custom',
      name: 'My Creation',
      wallFace: c('wallFace'),
      wallLight: c('wallLight'),
      wallDark: c('wallDark'),
      floor: c('floor'),
      floorLine: c('wallDark'),
      pellet: c('pellet'),
      powerPellet: c('powerPellet'),
      muncher: c('muncher'),
      muncherShade: c('wallDark'),
      ghostColors: const [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF4FA8C9),
        Color(0xFFE8A04C),
      ],
      frightBlue: const Color(0xFF3B5BA9),
      accent: c('accent'),
      accentLight: c('accent'),
      accentDark: c('wallDark'),
      bg: c('wallDark'),
      panel: c('wallFace'),
      text: const Color(0xFFF2EAD8),
      textDim: const Color(0xFF9AA3BE),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2).toInt();
    lastMode = (p.getInt(_kMode) ?? 0).clamp(0, 2).toInt();
    // Player name: prefer the order-safe JSON key. Migrate once from legacy
    // keys (plain string, then the unordered StringList, then the
    // pre-release JSON key).
    final nameRaw = p.getString(_kNameJson);
    if (nameRaw != null) {
      playerName = decodePlayerName(nameRaw);
    } else {
      final legacyJson = p.getString(_kNameJsonLegacy);
      final legacyStr = p.getString(_kNameLegacy);
      final legacyList = p.getStringList(_kNamesLegacy);
      final raw = legacyJson != null
          ? decodePlayerName(legacyJson)
          : legacyStr ??
              (legacyList != null && legacyList.isNotEmpty
                  ? legacyList.first
                  : null);
      playerName = raw == null || raw.trim().isEmpty ? defaultName : raw.trim();
    }
    themeId = p.getString(_kTheme) ?? 'midnight';
    muncherStyle = (p.getInt(_kMuncher) ?? 0).clamp(0, 7).toInt();
    wallStyle = (p.getInt(_kWall) ?? 0).clamp(0, 7).toInt();
    campaignLevel = (p.getInt(_kCampaignLevel) ?? 0).clamp(0, 99).toInt();
    endlessBest = p.getInt(_kEndlessBest) ?? 0;
    attackBest = p.getInt(_kAttackBest) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    campaignsCompleted = p.getInt(_kWins) ?? 0;
    totalPellets = p.getInt(_kPellets) ?? 0;
    totalGhosts = p.getInt(_kGhosts) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kMode, lastMode);
    await p.setString(_kNameJson, encodePlayerName(playerName));
    await p.remove(_kNameLegacy); // drop legacy keys for good
    await p.remove(_kNamesLegacy);
    await p.remove(_kNameJsonLegacy);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kMuncher, muncherStyle);
    await p.setInt(_kWall, wallStyle);
    await p.setInt(_kCampaignLevel, campaignLevel);
    await p.setInt(_kEndlessBest, endlessBest);
    await p.setInt(_kAttackBest, attackBest);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kWins, campaignsCompleted);
    await p.setInt(_kPellets, totalPellets);
    await p.setInt(_kGhosts, totalGhosts);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || MazeThemes.isProTheme(themeId)) {
      themeId = 'midnight';
      changed = true;
    }
    if (MuncherStyles.isPro(muncherStyle)) {
      muncherStyle = 0;
      changed = true;
    }
    if (WallStyles.isPro(wallStyle)) {
      wallStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return;
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0).toDouble();
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2).toInt();
    if (!isPro && v > 1) return; // Nightmare is a Pro feature
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setLastMode(int v) async {
    lastMode = v.clamp(0, 2).toInt();
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || MazeThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setMuncherStyle(int v) async {
    v = v.clamp(0, MuncherStyles.names.length - 1).toInt();
    if (!isPro && MuncherStyles.isPro(v)) return;
    muncherStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setWallStyle(int v) async {
    v = v.clamp(0, WallStyles.names.length - 1).toInt();
    if (!isPro && WallStyles.isPro(v)) return;
    wallStyle = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished run. [score] counts toward the per-mode best;
  /// [completedCampaign] true when all campaign mazes were cleared.
  Future<void> recordRun({
    required int mode,
    required int score,
    required int pellets,
    required int ghosts,
    bool completedCampaign = false,
    int reachedLevel = 0,
  }) async {
    gamesPlayed++;
    totalPellets += pellets;
    totalGhosts += ghosts;
    if (mode == 1 && score > endlessBest) endlessBest = score;
    if (mode == 2 && score > attackBest) attackBest = score;
    if (completedCampaign) {
      campaignsCompleted++;
      if (campaignLevel < reachedLevel) campaignLevel = reachedLevel;
    }
    notifyListeners();
    await _save();
  }
}
