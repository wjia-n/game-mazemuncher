import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/maze_engine.dart';
import 'maze_themes.dart';

/// Code-drawn maze art: beveled physical wall blocks, glossy candy pellets,
/// 8 original muncher characters, 4 ghost personalities. No image assets,
/// no neon — everything reads as tangible toy material with soft light.

double _cellOf(Size size, int w) => size.width / w;

/// Static layer: floor + walls. Repaints only when the maze changes.
class MazeStaticPainter extends CustomPainter {
  final MazeEngine engine;
  final MazeThemeDef theme;
  final int wallStyle;
  final int mazeId;
  MazeStaticPainter({
    required this.engine,
    required this.theme,
    required this.wallStyle,
    required this.mazeId,
  }) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = _cellOf(size, engine.w);
    // Floor.
    canvas.drawRect(
        Offset.zero & Size(engine.w * cell, engine.h * cell),
        Paint()..color = theme.floor);
    // Tile seams.
    final seam = Paint()
      ..color = theme.floorLine
      ..strokeWidth = 1;
    for (var x = 1; x < engine.w; x++) {
      canvas.drawLine(Offset(x * cell, 0), Offset(x * cell, engine.h * cell),
          seam);
    }
    for (var y = 1; y < engine.h; y++) {
      canvas.drawLine(Offset(0, y * cell), Offset(engine.w * cell, y * cell),
          seam);
    }
    // Walls.
    for (var y = 0; y < engine.h; y++) {
      for (var x = 0; x < engine.w; x++) {
        if (engine.maze[y][x] == '#') {
          _drawWall(canvas, Offset(x * cell, y * cell), cell);
        }
      }
    }
  }

  void _drawWall(Canvas canvas, Offset o, double cell) {
    final r = cell / 2;
    // Base block (shadow side).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx + 1, o.dy + 1, cell - 2, cell - 2),
          Radius.circular(r * 0.28)),
      Paint()..color = theme.wallDark,
    );
    // Face.
    final face = Rect.fromLTWH(
        o.dx + cell * 0.13, o.dy + cell * 0.13, cell * 0.74, cell * 0.74);
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(r * 0.24)),
      Paint()..color = theme.wallFace,
    );
    // Top bevel highlight.
    canvas.drawLine(
      Offset(face.left + 3, face.top + 2),
      Offset(face.right - 3, face.top + 2),
      Paint()
        ..color = theme.wallLight.withValues(alpha: 0.9)
        ..strokeWidth = max(1.5, cell * 0.05)
        ..strokeCap = StrokeCap.round,
    );
    // Style pattern, clipped to the face.
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(face, Radius.circular(r * 0.24)));
    final pat = Paint()..color = theme.wallLight.withValues(alpha: 0.35);
    final dark = Paint()..color = theme.wallDark.withValues(alpha: 0.4);
    switch (wallStyle) {
      case 0: // Brickwork: mortar lines
        canvas.drawLine(Offset(face.left, face.center.dy),
            Offset(face.right, face.center.dy), dark..strokeWidth = 2);
        canvas.drawLine(Offset(face.center.dx, face.top),
            Offset(face.center.dx, face.center.dy), dark..strokeWidth = 2);
        canvas.drawLine(
            Offset(face.left + face.width * 0.25, face.center.dy),
            Offset(face.left + face.width * 0.25, face.bottom),
            dark..strokeWidth = 2);
        canvas.drawLine(
            Offset(face.left + face.width * 0.75, face.center.dy),
            Offset(face.left + face.width * 0.75, face.bottom),
            dark..strokeWidth = 2);
        break;
      case 1: // Stone blocks: speckles
        final rnd = Random(o.dx.toInt() * 31 + o.dy.toInt() * 57);
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
              Offset(face.left + rnd.nextDouble() * face.width,
                  face.top + rnd.nextDouble() * face.height),
              max(1, cell * 0.03),
              rnd.nextBool() ? pat : dark);
        }
        break;
      case 2: // Wood planks: grain
        for (var i = 0; i < 3; i++) {
          final x = face.left + face.width * (0.25 + 0.25 * i);
          canvas.drawLine(Offset(x, face.top), Offset(x, face.bottom),
              dark..strokeWidth = 1.5);
        }
        break;
      case 3: // Candy stripes
        for (var i = -2; i < 4; i++) {
          canvas.drawLine(
              Offset(face.left + i * cell * 0.22, face.bottom),
              Offset(face.left + i * cell * 0.22 + cell * 0.3, face.top),
              pat..strokeWidth = cell * 0.09);
        }
        break;
      case 4: // Bamboo: nodes
        canvas.drawLine(Offset(face.center.dx, face.top),
            Offset(face.center.dx, face.bottom), dark..strokeWidth = 2.5);
        canvas.drawLine(Offset(face.left, face.center.dy),
            Offset(face.right, face.center.dy), pat..strokeWidth = 3);
        break;
      case 5: // Marble: veins
        final vein = Path()
          ..moveTo(face.left, face.top + face.height * 0.3)
          ..quadraticBezierTo(face.center.dx, face.top + face.height * 0.5,
              face.right, face.top + face.height * 0.25)
          ..moveTo(face.left, face.top + face.height * 0.7)
          ..quadraticBezierTo(face.center.dx, face.top + face.height * 0.9,
              face.right, face.top + face.height * 0.65);
        canvas.drawPath(
            vein, pat..style = PaintingStyle.stroke..strokeWidth = 1.5);
        break;
      case 6: // Riveted steel: corner rivets
        for (final c in [
          face.topLeft + const Offset(5, 5),
          face.topRight + const Offset(-5, 5),
          face.bottomLeft + const Offset(5, -5),
          face.bottomRight + const Offset(-5, -5),
        ]) {
          canvas.drawCircle(c, max(1.5, cell * 0.05), pat);
        }
        break;
      case 7: // Garden hedge: leafy scallops
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
              Offset(face.left + face.width * (0.15 + 0.23 * i),
                  face.top + face.height * 0.35),
              cell * 0.10,
              pat);
        }
        break;
      default:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MazeStaticPainter old) =>
      old.mazeId != mazeId ||
      old.theme != theme ||
      old.wallStyle != wallStyle;
}

/// Dynamic layer: pellets, fruit, muncher, ghosts, score pops.
class MazeDynamicPainter extends CustomPainter {
  final MazeEngine engine;
  final MazeThemeDef theme;
  final int muncherStyle;
  MazeDynamicPainter({
    required this.engine,
    required this.theme,
    required this.muncherStyle,
  }) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = _cellOf(size, engine.w);
    final dying = engine.phase == MazePhase.dying;

    // Pellets: glossy candy dots.
    for (final p in engine.pellets) {
      final c = Offset((p.x + 0.5) * cell, (p.y + 0.5) * cell);
      final r = cell * 0.11;
      canvas.drawCircle(c + Offset(0, 1), r, Paint()..color = Colors.black38);
      canvas.drawCircle(c, r, Paint()..color = theme.pellet);
      canvas.drawCircle(
          c + Offset(-r * 0.3, -r * 0.35),
          r * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.75));
    }
    // Power pellets: pulsing.
    final pulse = 0.5 + 0.5 * sin(engine.mouthT * 0.9);
    for (final p in engine.powers) {
      final c = Offset((p.x + 0.5) * cell, (p.y + 0.5) * cell);
      final r = cell * (0.24 + 0.07 * pulse);
      canvas.drawCircle(c + Offset(0, 2), r, Paint()..color = Colors.black38);
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 1.0,
              colors: [
                Colors.white.withValues(alpha: 0.9),
                theme.powerPellet,
                theme.powerPellet.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(Rect.fromCircle(center: c, radius: r)));
    }
    // Fruit (cherry).
    if (engine.fruit != null) {
      _drawCherry(canvas,
          Offset((engine.fruit!.x + 0.5) * cell, (engine.fruit!.y + 0.5) * cell),
          cell * 0.30);
    }
    // Ghosts under the muncher.
    for (var i = 0; i < engine.ghosts.length; i++) {
      _drawGhost(canvas, engine.ghosts[i], cell, i);
    }
    // Muncher (not drawn once fully popped).
    if (!(dying && engine.deathT >= 1)) {
      _drawMuncher(
          canvas,
          Offset(engine.pos.x * cell, engine.pos.y * cell),
          cell * 0.42,
          dying ? engine.deathT : -1);
    }
    // Score pops.
    for (final pop in engine.pops) {
      final a = (1 - pop.ageSecs / 1.1).clamp(0.0, 1.0).toDouble();
      final c = Offset(
          pop.pos.x * cell, (pop.pos.y - pop.ageSecs * 0.8) * cell);
      _text(canvas, pop.text, c, cell * 0.42,
          theme.accentLight.withValues(alpha: a));
    }
  }

  void _text(Canvas canvas, String s, Offset c, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: color,
              shadows: const [
                Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 3)
              ])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawCherry(Canvas canvas, Offset c, double r) {
    final stem = Paint()
      ..color = const Color(0xFF3E7A34)
      ..strokeWidth = max(1.5, r * 0.18)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(0, -r * 0.2), c + Offset(r * 0.5, -r * 1.1), stem);
    // Leaf.
    final leaf = Path()
      ..moveTo(c.dx + r * 0.5, c.dy - r * 1.1)
      ..quadraticBezierTo(c.dx + r * 1.1, c.dy - r * 1.3, c.dx + r * 1.3,
          c.dy - r * 0.8)
      ..quadraticBezierTo(
          c.dx + r * 0.9, c.dy - r * 0.7, c.dx + r * 0.5, c.dy - r * 1.1);
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF57A047));
    for (final dx in [-0.45, 0.45]) {
      final cc = c + Offset(r * dx, r * 0.25);
      canvas.drawCircle(cc + Offset(0, 1.5), r * 0.62,
          Paint()..color = Colors.black38);
      canvas.drawCircle(
          cc,
          r * 0.62,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 1.1,
              colors: const [
                Color(0xFFFF8A8A),
                Color(0xFFD92B2B),
                Color(0xFF8E1414)
              ],
            ).createShader(Rect.fromCircle(center: cc, radius: r * 0.62)));
    }
  }

  // ------------------------------------------------------------- muncher
  void _drawMuncher(Canvas canvas, Offset c, double r, double deathT) {
    final body = theme.muncher;
    final shade = theme.muncherShade;
    // Facing angle from direction (default: right).
    double ang = 0;
    final d = engine.dir.x == 0 && engine.dir.y == 0 ? engine.want : engine.dir;
    if (d.x == 1) {
      ang = 0;
    } else if (d.x == -1) {
      ang = pi;
    } else if (d.y == 1) {
      ang = pi / 2;
    } else if (d.y == -1) {
      ang = -pi / 2;
    }

    double mouth;
    double scale = 1;
    if (deathT >= 0) {
      // Dying: jaw unhinges, then the muncher pops.
      mouth = pi * 0.15 + deathT * pi * 0.85;
      if (deathT > 0.7) scale = 1 - (deathT - 0.7) / 0.3;
      if (scale <= 0) return;
    } else {
      mouth = (0.5 + 0.5 * sin(engine.mouthT * pi)) * 0.85 + 0.08;
    }
    final rr = r * scale;

    // Shadow.
    canvas.drawEllipse(
        Rect.fromCenter(
            center: c + Offset(0, rr * 0.9), width: rr * 1.5, height: rr * 0.4),
        Paint()..color = Colors.black.withValues(alpha: 0.35));

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(ang);

    if (muncherStyle == 1) {
      _muncherBoxy(canvas, rr, mouth, body, shade);
    } else {
      _muncherRound(canvas, rr, mouth, body, shade);
      switch (muncherStyle) {
        case 2:
          _hatKnight(canvas, rr);
          break;
        case 3:
          _hatChef(canvas, rr);
          break;
        case 4:
          _hatAstro(canvas, rr);
          break;
        case 5:
          _hatNinja(canvas, rr);
          break;
        case 6:
          _hatPumpkin(canvas, rr);
          break;
        case 7:
          _hatFrost(canvas, rr);
          break;
        default:
          break;
      }
    }
    canvas.restore();
  }

  void _muncherRound(
      Canvas canvas, double r, double mouth, Color body, Color shade) {
    // Body with soft top light.
    canvas.drawCircle(
        const Offset(0, 0),
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1.15,
            colors: [Colors.white.withValues(alpha: 0.55), body, shade],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)));
    // Wedge mouth.
    final mouthPath = Path()
      ..moveTo(0, 0)
      ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r), -mouth, mouth * 2,
          false)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF3A1C0C));
    // Cheek highlight.
    canvas.drawCircle(Offset(-r * 0.35, -r * 0.5), r * 0.16,
        Paint()..color = Colors.white.withValues(alpha: 0.5));
    // Eye (above the mouth, toward facing dir).
    final eyeC = Offset(r * 0.1, -r * 0.52);
    canvas.drawCircle(eyeC, r * 0.30, Paint()..color = Colors.white);
    canvas.drawCircle(eyeC + Offset(r * 0.10, 0), r * 0.15,
        Paint()..color = const Color(0xFF1A1A22));
    canvas.drawCircle(eyeC + Offset(r * 0.05, -r * 0.05), r * 0.05,
        Paint()..color = Colors.white);
  }

  void _muncherBoxy(
      Canvas canvas, double r, double mouth, Color body, Color shade) {
    final rect =
        RRect.fromRectAndRadius(Rect.fromCircle(center: Offset.zero, radius: r),
            Radius.circular(r * 0.35));
    canvas.drawRRect(rect, Paint()..color = shade);
    final inner = RRect.fromRectAndRadius(
        Rect.fromCircle(center: const Offset(0, -2), radius: r * 0.88),
        Radius.circular(r * 0.3));
    canvas.drawRRect(inner, Paint()..color = body);
    // Mouth grill.
    final mg = Path()
      ..moveTo(0, 0)
      ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r * 0.9), -mouth,
          mouth * 2, false)
      ..close();
    canvas.drawPath(mg, Paint()..color = const Color(0xFF2A2A33));
    // Visor eye.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(r * 0.05, -r * 0.5),
                width: r * 1.1,
                height: r * 0.42),
            Radius.circular(r * 0.2)),
        Paint()..color = const Color(0xFF20303F));
    canvas.drawCircle(Offset(r * 0.2, -r * 0.5), r * 0.12,
        Paint()..color = const Color(0xFF9BE4EC));
    // Antenna.
    canvas.drawLine(const Offset(0, 0) + Offset(-r * 0.5, -r * 0.9),
        Offset(-r * 0.5, -r * 1.3), Paint()..color = shade..strokeWidth = 3);
    canvas.drawCircle(Offset(-r * 0.5, -r * 1.35), r * 0.12,
        Paint()..color = theme.powerPellet);
  }

  void _hatKnight(Canvas canvas, double r) {
    // Iron helm dome.
    canvas.drawArc(Rect.fromCircle(center: Offset(-r * 0.1, -r * 0.25), radius: r * 0.95),
        pi * 1.05, pi * 0.9, true, Paint()..color = const Color(0xFF9AA2B2));
    canvas.drawArc(Rect.fromCircle(center: Offset(-r * 0.1, -r * 0.25), radius: r * 0.95),
        pi * 1.1, pi * 0.25, true, Paint()..color = const Color(0xFFC9D2E0));
    // Plume.
    final plume = Path()
      ..moveTo(-r * 0.15, -r * 1.15)
      ..quadraticBezierTo(r * 0.35, -r * 1.5, r * 0.15, -r * 1.05)
      ..close();
    canvas.drawPath(plume, Paint()..color = theme.ghostColors[0]);
  }

  void _hatChef(Canvas canvas, double r) {
    final hatC = Offset(-r * 0.1, -r * 1.05);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: hatC, width: r * 1.15, height: r * 0.62),
            Radius.circular(r * 0.28)),
        Paint()..color = const Color(0xFFF7F3E8));
    for (final dx in [-0.32, 0, 0.32]) {
      canvas.drawCircle(hatC + Offset(r * dx, -r * 0.28), r * 0.24,
          Paint()..color = const Color(0xFFF7F3E8));
    }
    canvas.drawRect(
        Rect.fromCenter(
            center: hatC + Offset(0, r * 0.42), width: r * 1.0, height: r * 0.22),
        Paint()..color = const Color(0xFFD9D2BE));
  }

  void _hatAstro(Canvas canvas, double r) {
    // Glass dome.
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 1.02),
        pi * 1.08, pi * 0.84, true,
        Paint()..color = const Color(0xFFBFE4EC).withValues(alpha: 0.45));
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 1.02),
        pi * 1.25, pi * 0.2, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12);
  }

  void _hatNinja(Canvas canvas, double r) {
    // Headband.
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r * 0.62), width: r * 2.0, height: r * 0.30),
        Paint()..color = const Color(0xFF2E3440));
    // Tails.
    final tails = Path()
      ..moveTo(-r * 0.9, -r * 0.62)
      ..quadraticBezierTo(-r * 1.5, -r * 0.5, -r * 1.45, -r * 0.05)
      ..quadraticBezierTo(-r * 1.15, -r * 0.35, -r * 0.9, -r * 0.45)
      ..close();
    canvas.drawPath(tails, Paint()..color = const Color(0xFF2E3440));
    canvas.drawCircle(Offset(r * 0.55, -r * 0.62), r * 0.10,
        Paint()..color = theme.powerPellet);
  }

  void _hatPumpkin(Canvas canvas, double r) {
    // Ridges.
    for (final dx in [-0.45, 0.45]) {
      canvas.drawArc(
          Rect.fromCircle(center: Offset(r * dx, 0), radius: r * 0.92),
          -pi / 2 - 0.5,
          1.0,
          false,
          Paint()
            ..color = theme.muncherShade
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.10);
    }
    // Stem.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(-r * 0.05, -r * 1.08),
                width: r * 0.28,
                height: r * 0.42),
            Radius.circular(r * 0.1)),
        Paint()..color = const Color(0xFF3E7A34));
  }

  void _hatFrost(Canvas canvas, double r) {
    // Snow cap.
    canvas.drawArc(Rect.fromCircle(center: Offset(-r * 0.05, -r * 0.2), radius: r * 0.98),
        pi * 1.02, pi * 0.96, true,
        Paint()..color = const Color(0xFFEAF4FB).withValues(alpha: 0.92));
    // Sparkles.
    final sp = Paint()..color = Colors.white;
    for (final o in [
      Offset(-r * 0.6, -r * 0.75),
      Offset(r * 0.1, -r * 0.95),
      Offset(r * 0.55, -r * 0.55),
    ]) {
      canvas.drawCircle(o, r * 0.07, sp);
    }
  }

  // -------------------------------------------------------------- ghosts
  void _drawGhost(Canvas canvas, Ghost g, double cell, int index) {
    final c = Offset(g.pos.x * cell, g.pos.y * cell);
    final r = cell * 0.42;
    final bodyColor = g.eyes
        ? Colors.transparent
        : (g.frightened
            ? (engine.frightT < 2 && (engine.mouthT * 2).floor().isEven
                ? Colors.white
                : theme.frightBlue)
            : theme.ghostColors[index % theme.ghostColors.length]);
    // Shadow.
    canvas.drawEllipse(
        Rect.fromCenter(
            center: c + Offset(0, r * 0.95), width: r * 1.5, height: r * 0.38),
        Paint()..color = Colors.black.withValues(alpha: 0.35));

    if (!g.eyes) {
      // Body: dome + wavy skirt.
      final wave = sin(engine.mouthT * 1.4 + index) * r * 0.08;
      final body = Path()
        ..moveTo(c.dx - r, c.dy + r * 0.7)
        ..lineTo(c.dx - r, c.dy - r * 0.1)
        ..arcTo(Rect.fromCircle(center: Offset(c.dx, c.dy - r * 0.1), radius: r),
            pi, -pi, false);
      const waves = 4;
      for (var i = 0; i <= waves; i++) {
        final x = c.dx + r - (2 * r * i / waves);
        final y = c.dy + r * 0.7 + (i.isEven ? wave : -wave);
        if (i == 0) {
          body.lineTo(x, y);
        } else {
          body.quadraticBezierTo(
              x + r / waves, c.dy + r * 0.7 + (i.isEven ? -wave : wave), x, y);
        }
      }
      body.close();
      canvas.drawPath(
          body,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.5),
              radius: 1.2,
              colors: [
                Colors.white.withValues(alpha: 0.35),
                bodyColor,
                bodyColor.withValues(alpha: 0.85)
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(Rect.fromCircle(center: c, radius: r * 1.4)));
    }
    // Face.
    final look = Offset(g.dir.x * r * 0.12, g.dir.y * r * 0.12);
    if (g.frightened && !g.eyes) {
      // Scared face: dot eyes + zigzag mouth.
      for (final dx in [-0.32, 0.32]) {
        canvas.drawCircle(c + Offset(r * dx, -r * 0.25), r * 0.13,
            Paint()..color = Colors.white);
        canvas.drawCircle(c + Offset(r * dx, -r * 0.25), r * 0.06,
            Paint()..color = const Color(0xFFD94F3D));
      }
      final zm = Path();
      for (var i = 0; i < 5; i++) {
        final x = c.dx - r * 0.4 + i * r * 0.2;
        final y = c.dy + r * 0.35 + (i.isEven ? 0 : r * 0.12);
        if (i == 0) {
          zm.moveTo(x, y);
        } else {
          zm.lineTo(x, y);
        }
      }
      canvas.drawPath(
          zm,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.5, r * 0.09)
            ..strokeCap = StrokeCap.round);
    } else {
      for (final dx in [-0.32, 0.32]) {
        final ec = c + Offset(r * dx, -r * 0.28) + look;
        canvas.drawEllipse(
            Rect.fromCenter(center: ec, width: r * 0.42, height: r * 0.52),
            Paint()..color = Colors.white);
        canvas.drawCircle(ec + look, r * 0.20,
            Paint()..color = const Color(0xFF1E3A6E));
        canvas.drawCircle(ec + look + Offset(-r * 0.05, -r * 0.06), r * 0.07,
            Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MazeDynamicPainter old) => true;
}
