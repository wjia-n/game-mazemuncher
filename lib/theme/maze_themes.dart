import 'package:flutter/material.dart';

/// Theme, muncher-style and wall-style catalogs for Maze Muncher.
///
/// Every theme stays inside a tactile, physical toy world — chunky beveled
/// maze walls, glossy candy pellets, soft studio light. No neon, no
/// cyberpunk, no generic dashboard looks. The maze may be dark, but it reads
/// as physical material (wood, stone, cookie, copper…), never as glow.
class MazeThemeDef {
  final String id;
  final String name;
  final Color wallFace; // top face of a wall block
  final Color wallLight; // bevel highlight
  final Color wallDark; // bevel shadow / base
  final Color floor;
  final Color floorLine; // subtle tile seams
  final Color pellet;
  final Color powerPellet;
  final Color muncher; // default muncher body color
  final Color muncherShade;
  final List<Color> ghostColors; // 4 ghost personalities
  final Color frightBlue; // frightened ghost body
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color bg; // screen backdrop behind the maze
  final Color panel; // HUD / card panels
  final Color text;
  final Color textDim;

  const MazeThemeDef({
    required this.id,
    required this.name,
    required this.wallFace,
    required this.wallLight,
    required this.wallDark,
    required this.floor,
    required this.floorLine,
    required this.pellet,
    required this.powerPellet,
    required this.muncher,
    required this.muncherShade,
    required this.ghostColors,
    required this.frightBlue,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.bg,
    required this.panel,
    required this.text,
    required this.textDim,
  });
}

class MazeThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'midnight',
    'cookie',
    'stone',
    'candy',
  ];

  static bool isProTheme(String id) =>
      id != 'custom' && !freeThemeIds.contains(id);

  static const List<MazeThemeDef> all = [
    MazeThemeDef(
      id: 'midnight',
      name: 'Midnight Diner',
      wallFace: Color(0xFF2E3D5C),
      wallLight: Color(0xFF5B719E),
      wallDark: Color(0xFF141B2E),
      floor: Color(0xFF0E1424),
      floorLine: Color(0xFF1B2540),
      pellet: Color(0xFFE8C76A),
      powerPellet: Color(0xFFFFD968),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF4FA8C9),
        Color(0xFFE8A04C),
      ],
      frightBlue: Color(0xFF3B5BA9),
      accent: Color(0xFFE8B93E),
      accentLight: Color(0xFFFFD968),
      accentDark: Color(0xFF9A7420),
      bg: Color(0xFF0B1020),
      panel: Color(0xFF1A2340),
      text: Color(0xFFF2EAD8),
      textDim: Color(0xFF9AA3BE),
    ),
    MazeThemeDef(
      id: 'cookie',
      name: 'Cookie Tin',
      wallFace: Color(0xFFC89B62),
      wallLight: Color(0xFFEBCB97),
      wallDark: Color(0xFF7A5230),
      floor: Color(0xFF2A1D12),
      floorLine: Color(0xFF3A2A1C),
      pellet: Color(0xFFF3E2B8),
      powerPellet: Color(0xFFFFE9B0),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF4FA8C9),
        Color(0xFFE8A04C),
      ],
      frightBlue: Color(0xFF5B7AC9),
      accent: Color(0xFFD9A441),
      accentLight: Color(0xFFF2C86E),
      accentDark: Color(0xFF8A6420),
      bg: Color(0xFF20140B),
      panel: Color(0xFF33241A),
      text: Color(0xFFF7EDDC),
      textDim: Color(0xFFB9A488),
    ),
    MazeThemeDef(
      id: 'stone',
      name: 'Stone Keep',
      wallFace: Color(0xFF7C8494),
      wallLight: Color(0xFFB4BCCB),
      wallDark: Color(0xFF3E4452),
      floor: Color(0xFF23262E),
      floorLine: Color(0xFF30343E),
      pellet: Color(0xFFD8DCE6),
      powerPellet: Color(0xFFFFFFFF),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFC94F3D),
        Color(0xFFD98BB0),
        Color(0xFF5FA8C9),
        Color(0xFFD9A04C),
      ],
      frightBlue: Color(0xFF3B5BA9),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      bg: Color(0xFF1B1D23),
      panel: Color(0xFF2E323C),
      text: Color(0xFFF2F0E8),
      textDim: Color(0xFF9AA0B2),
    ),
    MazeThemeDef(
      id: 'candy',
      name: 'Candy Shop',
      wallFace: Color(0xFFE89BC0),
      wallLight: Color(0xFFFACBDE),
      wallDark: Color(0xFF9E5B7D),
      floor: Color(0xFF3A2330),
      floorLine: Color(0xFF4C3042),
      pellet: Color(0xFFFFF2E0),
      powerPellet: Color(0xFFFF9DC4),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFB04F86),
        Color(0xFF4FA8C9),
        Color(0xFFE8A04C),
      ],
      frightBlue: Color(0xFF7B6BC9),
      accent: Color(0xFFD96A9B),
      accentLight: Color(0xFFF49BC0),
      accentDark: Color(0xFF96486C),
      bg: Color(0xFF2E1B26),
      panel: Color(0xFF432A3B),
      text: Color(0xFFFFF0F6),
      textDim: Color(0xFFC9A3B5),
    ),
    MazeThemeDef(
      id: 'emerald',
      name: 'Emerald Vault',
      wallFace: Color(0xFF2F6B52),
      wallLight: Color(0xFF5CA87E),
      wallDark: Color(0xFF14382A),
      floor: Color(0xFF0F231B),
      floorLine: Color(0xFF1B3A2D),
      pellet: Color(0xFFF0D98A),
      powerPellet: Color(0xFFFFE9A0),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF6FC9B8),
        Color(0xFFE8A04C),
      ],
      frightBlue: Color(0xFF3B6BA9),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      bg: Color(0xFF0C1B14),
      panel: Color(0xFF173023),
      text: Color(0xFFF2F0DC),
      textDim: Color(0xFF9AB5A4),
    ),
    MazeThemeDef(
      id: 'copper',
      name: 'Copper Kitchen',
      wallFace: Color(0xFFB87333),
      wallLight: Color(0xFFE8A96A),
      wallDark: Color(0xFF6E3E1A),
      floor: Color(0xFF241407),
      floorLine: Color(0xFF38220F),
      pellet: Color(0xFFF2D9A0),
      powerPellet: Color(0xFFFFE9B0),
      muncher: Color(0xFFFFD968),
      muncherShade: Color(0xFFC98A20),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF4FA8C9),
        Color(0xFFB87333),
      ],
      frightBlue: Color(0xFF4B6BA9),
      accent: Color(0xFFE09E5A),
      accentLight: Color(0xFFF2BE85),
      accentDark: Color(0xFF9A6428),
      bg: Color(0xFF1C1006),
      panel: Color(0xFF33200E),
      text: Color(0xFFF9EFDD),
      textDim: Color(0xFFBFA07C),
    ),
    MazeThemeDef(
      id: 'cherrywood',
      name: 'Cherry Parlor',
      wallFace: Color(0xFF7C3F24),
      wallLight: Color(0xFFB06A44),
      wallDark: Color(0xFF381408),
      floor: Color(0xFF1E0F08),
      floorLine: Color(0xFF301A0F),
      pellet: Color(0xFFF0D0A0),
      powerPellet: Color(0xFFFFD9A0),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF4FA8C9),
        Color(0xFFE8A04C),
      ],
      frightBlue: Color(0xFF3B5BA9),
      accent: Color(0xFFD98A4C),
      accentLight: Color(0xFFF0B47E),
      accentDark: Color(0xFF8A5228),
      bg: Color(0xFF180C06),
      panel: Color(0xFF2C1810),
      text: Color(0xFFF7EBDB),
      textDim: Color(0xFFB8998A),
    ),
    MazeThemeDef(
      id: 'ocean',
      name: 'Ocean Grotto',
      wallFace: Color(0xFF2F7B8C),
      wallLight: Color(0xFF6BB8C9),
      wallDark: Color(0xFF14424E),
      floor: Color(0xFF0E242A),
      floorLine: Color(0xFF1A3A44),
      pellet: Color(0xFFE8F4F0),
      powerPellet: Color(0xFFBFF0E4),
      muncher: Color(0xFFF5B83D),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFE86A5A),
        Color(0xFFE88BB0),
        Color(0xFF7FD4E8),
        Color(0xFFE8A04C),
      ],
      frightBlue: Color(0xFF2B4BA9),
      accent: Color(0xFF5FC9D4),
      accentLight: Color(0xFF9BE4EC),
      accentDark: Color(0xFF2E7E88),
      bg: Color(0xFF0B1D22),
      panel: Color(0xFF163038),
      text: Color(0xFFEFFAF8),
      textDim: Color(0xFF8FB5BC),
    ),
    MazeThemeDef(
      id: 'bakery',
      name: 'Sunset Bakery',
      wallFace: Color(0xFFD97B3F),
      wallLight: Color(0xFFF2B078),
      wallDark: Color(0xFF7E3E1A),
      floor: Color(0xFF2B1608),
      floorLine: Color(0xFF3E2410),
      pellet: Color(0xFFFFF0D8),
      powerPellet: Color(0xFFFFC46B),
      muncher: Color(0xFFFFD968),
      muncherShade: Color(0xFFC98A20),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF4FA8C9),
        Color(0xFFB87333),
      ],
      frightBlue: Color(0xFF4B5BA9),
      accent: Color(0xFFE8A04C),
      accentLight: Color(0xFFF2C078),
      accentDark: Color(0xFF9A6428),
      bg: Color(0xFF221107),
      panel: Color(0xFF38200F),
      text: Color(0xFFFBEFDD),
      textDim: Color(0xFFC2A07C),
    ),
    MazeThemeDef(
      id: 'library',
      name: 'Royal Library',
      wallFace: Color(0xFF5A3A5E),
      wallLight: Color(0xFF8C5F92),
      wallDark: Color(0xFF2C1830),
      floor: Color(0xFF1E1420),
      floorLine: Color(0xFF2E2232),
      pellet: Color(0xFFF0E0B8),
      powerPellet: Color(0xFFFFE9A0),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFC97BB0),
        Color(0xFF6FA8C9),
        Color(0xFFD9A04C),
      ],
      frightBlue: Color(0xFF4B3BA9),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      bg: Color(0xFF170F1B),
      panel: Color(0xFF2A1F30),
      text: Color(0xFFF5EDDD),
      textDim: Color(0xFFA89AB0),
    ),
    MazeThemeDef(
      id: 'mint',
      name: 'Mint Garden',
      wallFace: Color(0xFF6BBF8F),
      wallLight: Color(0xFFA8E0BE),
      wallDark: Color(0xFF2F6B4A),
      floor: Color(0xFF12291C),
      floorLine: Color(0xFF1E3E2B),
      pellet: Color(0xFFFFFFE8),
      powerPellet: Color(0xFFD8F4C8),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFE86A5A),
        Color(0xFFE8A0B8),
        Color(0xFF4FC9A8),
        Color(0xFFE8B04C),
      ],
      frightBlue: Color(0xFF3B7BA9),
      accent: Color(0xFF8FD48F),
      accentLight: Color(0xFFBCE8BC),
      accentDark: Color(0xFF4E8A4E),
      bg: Color(0xFF0F2117),
      panel: Color(0xFF1C3527),
      text: Color(0xFFEFF7EC),
      textDim: Color(0xFF93B39A),
    ),
    MazeThemeDef(
      id: 'charcoal',
      name: 'Charcoal Loft',
      wallFace: Color(0xFF4A4E58),
      wallLight: Color(0xFF7E8490),
      wallDark: Color(0xFF22242A),
      floor: Color(0xFF141518),
      floorLine: Color(0xFF22242A),
      pellet: Color(0xFFF2C078),
      powerPellet: Color(0xFFFF9D4C),
      muncher: Color(0xFFF59E2C),
      muncherShade: Color(0xFFB25E12),
      ghostColors: [
        Color(0xFFD94F3D),
        Color(0xFFE88BB0),
        Color(0xFF7FA8C9),
        Color(0xFFE8A04C),
      ],
      frightBlue: Color(0xFF4B5BA9),
      accent: Color(0xFFE07B39),
      accentLight: Color(0xFFF2A468),
      accentDark: Color(0xFF9A5220),
      bg: Color(0xFF0F1013),
      panel: Color(0xFF22242A),
      text: Color(0xFFF2EEE6),
      textDim: Color(0xFF9A968C),
    ),
  ];

  static MazeThemeDef byId(String id, {MazeThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Muncher character styles — all drawn in code (CustomPainter), original art.
/// First 3 are FREE; the rest are PRO.
class MuncherStyles {
  static const List<String> names = [
    'Classic Chomper',
    'Boxy Bot',
    'Sir Chompalot',
    'Chef Munch',
    'Astro Muncher',
    'Shadow Nibbler',
    'Pumpkin Pal',
    'Frosty',
  ];
  static const List<String> blurb = [
    'The original tangerine chomper',
    'A sturdy little tin muncher',
    'A knight with an iron appetite',
    'Serves pellets with style',
    'Munching among the stars',
    'Silent, swift, snacky',
    'Spooky-season snacker',
    'Cool-headed pellet pro',
  ];
  static bool isPro(int i) => i >= 3;
}

/// Maze wall material styles — drawn in code as physical materials.
/// First 3 are FREE; the rest are PRO.
class WallStyles {
  static const List<String> names = [
    'Brickwork',
    'Stone Blocks',
    'Wood Planks',
    'Candy Stripes',
    'Bamboo',
    'Marble Slabs',
    'Riveted Steel',
    'Garden Hedge',
  ];
  static const List<String> blurb = [
    'Classic baked bricks',
    'Heavy granite blocks',
    'Warm timber planks',
    'Sweet striped candy',
    'Fresh-cut bamboo',
    'Polished marble',
    'Bolted iron plates',
    'Trimmed leafy hedge',
  ];
  static bool isPro(int i) => i >= 3;
}
