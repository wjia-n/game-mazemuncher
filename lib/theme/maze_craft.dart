import 'package:flutter/material.dart';
import 'maze_themes.dart';

/// Maze Muncher design system — chunky physical toy materials, soft studio
/// light, readable everywhere. No neon, no cyberpunk, no generic Material
/// look. All widgets take an optional [MazeThemeDef] and default to the
/// Midnight Diner theme.
class MazeCraft {
  static const displayFont = 'serif';

  static TextStyle display(double size,
          {Color? color, MazeThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFFFD968),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xAA000000), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, MazeThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.text ?? const Color(0xFFF2EAD8),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, MazeThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFFFD968),
        letterSpacing: 0.8,
      );

  static ThemeData theme([MazeThemeDef? t]) {
    t ??= MazeThemes.byId('midnight');
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.bg,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: t.accent,
        onPrimary: t.bg,
        secondary: t.accentLight,
        onSecondary: t.bg,
        surface: t.panel,
        onSurface: t.text,
        error: t.ghostColors[0],
        onError: t.text,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.panel),
    );
  }
}

/// Dark textured backdrop with a soft vignette, theme-aware.
class MazeBackdrop extends StatelessWidget {
  final Widget child;
  final MazeThemeDef? theme;
  const MazeBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? MazeThemes.byId('midnight');
    return Container(
      decoration: BoxDecoration(color: t.bg),
      child: CustomPaint(
        painter: _MazeBackdropPainter(t),
        child: child,
      ),
    );
  }
}

class _MazeBackdropPainter extends CustomPainter {
  final MazeThemeDef t;
  _MazeBackdropPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.15,
      colors: [
        t.panel.withValues(alpha: 0.5),
        t.bg.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.55),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A chunky toy button with bevel — looks physically pressable.
class MunchButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final MazeThemeDef? theme;
  final IconData? icon;

  const MunchButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 240,
    this.fontSize = 19,
    this.theme,
    this.icon,
  });

  @override
  State<MunchButton> createState() => _MunchButtonState();
}

class _MunchButtonState extends State<MunchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? MazeThemes.byId('midnight');
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [t.accentLight, t.accent, t.accentDark]
                : [t.panel, t.bg],
          ),
          border: Border.all(
              color: enabled
                  ? t.accentLight
                  : t.textDim.withValues(alpha: 0.4),
              width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: _pressed ? 0.0 : 0.18),
              offset: const Offset(0, -2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  color: enabled ? t.bg : t.textDim.withValues(alpha: 0.5),
                  size: widget.fontSize + 4),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                style: MazeCraft.display(widget.fontSize,
                    theme: t,
                    color: enabled ? t.bg : t.textDim.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An engraved plaque for titles.
class CraftPlaque extends StatelessWidget {
  final String title;
  final String? subtitle;
  final MazeThemeDef? theme;
  const CraftPlaque({super.key, required this.title, this.subtitle, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? MazeThemes.byId('midnight');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.panel, t.bg],
        ),
        border: Border.all(color: t.accent, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 6),
              blurRadius: 12),
          BoxShadow(
              color: t.accentLight.withValues(alpha: 0.5),
              offset: const Offset(0, -1),
              blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: MazeCraft.display(30, theme: t),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: MazeCraft.body(14,
                    theme: t, color: t.textDim),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// A chunky toggle for settings.
class CraftToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final MazeThemeDef? theme;
  const CraftToggle(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? MazeThemes.byId('midnight');
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? t.accentDark : t.bg,
          border: Border.all(color: t.accent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bead volume slider on a rail.
class BeadSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final MazeThemeDef? theme;
  const BeadSlider(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? MazeThemes.byId('midnight');
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: t.accent,
        inactiveTrackColor: t.bg,
        thumbShape: _BeadThumb(t),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _BeadThumb extends SliderComponentShape {
  final MazeThemeDef t;
  const _BeadThumb(this.t);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(center + const Offset(0, 2), 12,
        Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [t.accentLight, t.accent, t.accentDark],
          ).createShader(Rect.fromCircle(center: center, radius: 11)));
  }
}

/// A labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final MazeThemeDef? theme;
  const SettingRow(
      {super.key, required this.label, required this.control, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? MazeThemes.byId('midnight');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: t.panel.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: MazeCraft.body(16, theme: t))),
          control,
        ],
      ),
    );
  }
}
