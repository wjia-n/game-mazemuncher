import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

const _maps = [
  [
    "###################",
    "#........#........#",
    "#.##.###.#.###.##.#",
    "#o...............o#",
    "#.##.#.#####.#.##.#",
    "#....#..###..#....#",
    "####.#..###..#.####",
    "#......#####......#",
    "####.#..###..#.####",
    "#....#..###..#....#",
    "#.##.#.#####.#.##.#",
    "#o...............o#",
    "#.##.###.#.###.##.#",
    "#........P........#",
    "###################",
  ],
  [
    "###################",
    "#o......###......o#",
    "#.##.#.......#.##.#",
    "#....#.#####.#....#",
    "###..#.#...#.#..###",
    "#....#.#...#.#....#",
    "#.##.#.#####.#.##.#",
    "#.................#",
    "#.##.#.#####.#.##.#",
    "#....#...#...#....#",
    "##.#.#.#...#.#.#.##",
    "#..#...#...#...#..#",
    "#.##.#.#####.#.##.#",
    "#o......#P#......o#",
    "###################",
  ],
  [
    "###################",
    "#........#........#",
    "#.######.#.######.#",
    "#o#.....#.#.....#o#",
    "#.#.###.#.#.###.#.#",
    "#.#.#.......#.#.#.#",
    "#.#.#.#####.#.#.#.#",
    "#...#.#...#.#.#...#",
    "###.#.#.#.#.#.#.###",
    "#...#.#...#.#.#...#",
    "#.#.#.#####.#.#.#.#",
    "#.#.#.......#.#.#.#",
    "#.#.###.#.#.###.#.#",
    "#o#.....#P#.....#o#",
    "###################",
  ],
];

class _Ghost {
  Point<double> pos;
  Point<int> dir;
  final Color color;
  final int kind; // 0 chaser, 1 ambusher, 2 shy, 3 random
  bool frightened = false;
  bool eyes = false;
  _Ghost(this.pos, this.dir, this.color, this.kind);
}

class MazeMuncherScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const MazeMuncherScreen({super.key, required this.players, required this.callbacks});

  @override
  State<MazeMuncherScreen> createState() => _MazeMuncherScreenState();
}

class _MazeMuncherScreenState extends State<MazeMuncherScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  late List<List<String>> _maze;
  int _w = 19, _h = 15;
  final Set<Point<int>> _pellets = {};
  final Set<Point<int>> _powers = {};
  Point<double> _pos = const Point(0, 0);
  Point<int> _dir = const Point(0, 0);
  Point<int> _want = const Point(1, 0);
  final List<_Ghost> _ghosts = [];
  Point<int> _playerStart = const Point(9, 13);

  int _mazeIdx = 0, _lives = 3, _eaten = 0;
  double _frightT = 0, _mouthT = 0;
  double _modeT = 0;
  int _modeIdx = 0; // even = scatter, odd = chase
  int _ghostChain = 0;
  Point<int>? _fruit;
  double _fruitT = 0;
  bool _fruitSpawned70 = false, _fruitSpawned140 = false;
  bool _over = false;
  String _banner = '';
  double _bannerT = 0;
  final _rnd = Random();

  static const _modeDur = [7.0, 20.0, 7.0, 20.0, 5.0, 1e9];
  static const _ghostCols = [Colors.red, Colors.pink, Colors.cyan, Colors.orange];
  static const _corners = [Point(1, 1), Point(17, 1), Point(1, 13), Point(17, 13)];

  bool get _scatter => _modeIdx.isEven;

  @override
  void initState() {
    super.initState();
    _loadMaze();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool _wall(int x, int y) {
    if (x < 0 || y < 0 || x >= _w || y >= _h) return true;
    return _maze[y][x] == '#';
  }

  bool _canGo(Point<int> t, Point<int> d) => !_wall(t.x + d.x, t.y + d.y);

  void _loadMaze() {
    final raw = _maps[_mazeIdx];
    _h = raw.length;
    _w = raw[0].length;
    _maze = [for (final row in raw) row.split('')];
    _pellets.clear();
    _powers.clear();
    for (var y = 0; y < _h; y++) {
      for (var x = 0; x < _w; x++) {
        final c = _maze[y][x];
        if (c == '.') _pellets.add(Point(x, y));
        if (c == 'o') _powers.add(Point(x, y));
        if (c == 'P') {
          _playerStart = Point(x, y);
          _maze[y][x] = ' ';
        }
      }
    }
    // keep only reachable pellets (guarantees winnable mazes)
    final seen = <Point<int>>{_playerStart};
    final q = <Point<int>>[_playerStart];
    const dirs = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
    while (q.isNotEmpty) {
      final p = q.removeLast();
      for (final d in dirs) {
        final n = Point(p.x + d.x, p.y + d.y);
        if (!_wall(n.x, n.y) && seen.add(n)) q.add(n);
      }
    }
    _pellets.removeWhere((p) => !seen.contains(p));
    _powers.removeWhere((p) => !seen.contains(p));

    _resetActors();
    _eaten = 0;
    _frightT = 0;
    _modeIdx = 0;
    _modeT = 0;
    _fruit = null;
    _fruitT = 0;
    _fruitSpawned70 = false;
    _fruitSpawned140 = false;
    _banner = 'MAZE ${_mazeIdx + 1}';
    _bannerT = 1.6;
  }

  void _resetActors() {
    _pos = Point(_playerStart.x + 0.5, _playerStart.y + 0.5);
    _dir = const Point(0, 0);
    _want = const Point(-1, 0);
    _ghosts.clear();
    // spawn ghosts on open tiles near the middle
    final spots = <Point<int>>[];
    outer:
    for (var r = 0; r < 40; r++) {
      for (var y = 5; y < 10; y++) {
        for (var x = 6; x < 13; x++) {
          if (!_wall(x, y) && !spots.contains(Point(x, y))) {
            spots.add(Point(x, y));
            if (spots.length == 4) break outer;
          }
        }
      }
    }
    const dirs = [Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1)];
    for (var i = 0; i < 4; i++) {
      final s = spots[i % spots.length];
      _ghosts.add(_Ghost(Point(s.x + 0.5, s.y + 0.5), dirs[i % 4], _ghostCols[i], i));
    }
    _frightT = 0;
    _ghostChain = 0;
  }

  void _addScore(int pts) {
    widget.players[0].score += pts;
    widget.callbacks.refreshHud();
  }

  Point<int> _tileOf(Point<double> p) => Point(p.x.floor(), p.y.floor());

  void _tick(Duration now) {
    if (_over) {
      _last = now;
      return;
    }
    final dt = min((now - _last).inMicroseconds / 1e6, 1 / 30);
    _last = now;
    _mouthT += dt * 10;
    _bannerT = max(0, _bannerT - dt);

    // mode schedule
    if (_frightT <= 0) {
      _modeT += dt;
      if (_modeT >= _modeDur[_modeIdx]) {
        _modeT = 0;
        _modeIdx = min(_modeIdx + 1, _modeDur.length - 1);
      }
    } else {
      _frightT -= dt;
      if (_frightT <= 0) {
        for (final g in _ghosts) {
          g.frightened = false;
        }
        _ghostChain = 0;
      }
    }

    // fruit timer
    if (_fruit != null) {
      _fruitT -= dt;
      if (_fruitT <= 0) _fruit = null;
    }

    _movePlayer(dt);
    for (final g in _ghosts) {
      _moveGhost(g, dt);
    }
    _checkCollisions();

    if (mounted) setState(() {});
  }

  void _movePlayer(double dt) {
    var remaining = 7.4 * dt;
    var guard = 0;
    while (remaining > 1e-9 && guard++ < 8) {
      if (_dir.x == 0 && _dir.y == 0) {
        if (_canGo(_tileOf(_pos), _want)) {
          _dir = _want;
        } else {
          break;
        }
      }
      final tile = _tileOf(_pos);
      final nt = Point(tile.x + _dir.x, tile.y + _dir.y);
      if (_wall(nt.x, nt.y)) {
        // snap to center, stop
        _pos = Point(tile.x + 0.5, tile.y + 0.5);
        _dir = const Point(0, 0);
        break;
      }
      final center = Point(nt.x + 0.5, nt.y + 0.5);
      final dist = (_dir.x * (center.x - _pos.x) + _dir.y * (center.y - _pos.y));
      if (dist <= remaining) {
        _pos = center;
        remaining -= dist;
        _onArrivePlayer(nt);
        // choose direction at center
        if (_canGo(nt, _want)) {
          _dir = _want;
        } else if (!_canGo(nt, _dir)) {
          _dir = const Point(0, 0);
        }
      } else {
        _pos = Point(_pos.x + _dir.x * remaining, _pos.y + _dir.y * remaining);
        remaining = 0;
      }
    }
  }

  void _onArrivePlayer(Point<int> t) {
    if (_pellets.remove(t)) {
      _addScore(10);
      _eaten++;
      Sfx.tap();
      _maybeFruit();
      _checkWin();
    } else if (_powers.remove(t)) {
      _addScore(50);
      _eaten++;
      _frightT = 7;
      _ghostChain = 0;
      for (final g in _ghosts) {
        if (!g.eyes) g.frightened = true;
      }
      Sfx.win();
      _maybeFruit();
      _checkWin();
    }
    if (_fruit != null && t == _fruit) {
      _addScore(300 * (_mazeIdx + 1));
      _fruit = null;
      _banner = 'CHERRY! 🍒';
      _bannerT = 1.2;
      Sfx.win();
    }
  }

  void _maybeFruit() {
    if (!_fruitSpawned70 && _eaten >= 70) {
      _fruitSpawned70 = true;
      _fruit = _playerStart;
      _fruitT = 9;
    } else if (!_fruitSpawned140 && _eaten >= 140) {
      _fruitSpawned140 = true;
      _fruit = _playerStart;
      _fruitT = 9;
    }
  }

  void _checkWin() {
    if (_pellets.isEmpty && _powers.isEmpty && !_over) {
      if (_mazeIdx >= 2) {
        _finish(true);
      } else {
        _mazeIdx++;
        _loadMaze();
        Sfx.win();
      }
    }
  }

  Point<int> _ghostTarget(_Ghost g) {
    final pt = _tileOf(_pos);
    if (g.eyes) return const Point(9, 7);
    if (g.frightened) return Point(_rnd.nextInt(_w), _rnd.nextInt(_h));
    if (_scatter) return _corners[g.kind];
    switch (g.kind) {
      case 0:
        return pt;
      case 1:
        return Point(pt.x + _dir.x * 4, pt.y + _dir.y * 4);
      case 2:
        final d = (pt.x - _tileOf(g.pos).x).abs() + (pt.y - _tileOf(g.pos).y).abs();
        return d > 8 ? pt : _corners[g.kind];
      default:
        return Point(_rnd.nextInt(_w), _rnd.nextInt(_h));
    }
  }

  void _moveGhost(_Ghost g, double dt) {
    final speed = g.eyes ? 11.0 : (g.frightened ? 4.4 : 6.4);
    var remaining = speed * dt;
    var guard = 0;
    const dirs = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
    while (remaining > 1e-9 && guard++ < 8) {
      final tile = _tileOf(g.pos);
      final nt = Point(tile.x + g.dir.x, tile.y + g.dir.y);
      final center = Point(nt.x + 0.5, nt.y + 0.5);
      final dist = g.dir.x * (center.x - g.pos.x) + g.dir.y * (center.y - g.pos.y);
      if (dist <= remaining) {
        g.pos = center;
        remaining -= dist;
        if (g.eyes && nt == const Point(9, 7)) {
          g.eyes = false;
          g.frightened = _frightT > 0;
        }
        // choose next dir (no reverse)
        final rev = Point(-g.dir.x, -g.dir.y);
        final options = dirs.where((d) => d != rev && _canGo(nt, d)).toList();
        if (options.isEmpty) {
          final back = dirs.where((d) => _canGo(nt, d)).toList();
          g.dir = back.isEmpty ? const Point(0, 0) : back[_rnd.nextInt(back.length)];
        } else if (options.length == 1 || g.kind == 3 && !g.eyes) {
          g.dir = options[_rnd.nextInt(options.length)];
        } else {
          final target = _ghostTarget(g);
          options.sort((a, b) {
            final da = (nt.x + a.x - target.x).abs() + (nt.y + a.y - target.y).abs();
            final db = (nt.x + b.x - target.x).abs() + (nt.y + b.y - target.y).abs();
            return da.compareTo(db);
          });
          g.dir = options.first;
        }
      } else {
        g.pos = Point(g.pos.x + g.dir.x * remaining, g.pos.y + g.dir.y * remaining);
        remaining = 0;
      }
    }
  }

  void _checkCollisions() {
    for (final g in _ghosts) {
      final d = (g.pos.x - _pos.x).abs() + (g.pos.y - _pos.y).abs();
      if (d < 0.7 && !g.eyes) {
        if (g.frightened) {
          g.frightened = false;
          g.eyes = true;
          final pts = 200 << _ghostChain;
          _ghostChain = min(_ghostChain + 1, 3);
          _addScore(pts);
          _banner = '+$pts';
          _bannerT = 1.0;
          Sfx.win();
        } else {
          _caught();
          return;
        }
      }
    }
  }

  void _caught() {
    _lives--;
    if (_lives <= 0) {
      _finish(false);
    } else {
      _banner = 'OUCH! ${'❤️' * _lives} left';
      _bannerT = 1.4;
      Sfx.lose();
      _resetActors();
    }
  }

  void _finish(bool won) {
    if (_over) return;
    _over = true;
    _ticker.stop();
    final s = widget.players[0].score;
    if (won) {
      Sfx.win();
      widget.callbacks.finish(
        headline: 'Maze Master! 👻🏆',
        subline: 'All 3 mazes munched with $s points.',
      );
    } else {
      Sfx.lose();
      widget.callbacks.finish(
        headline: 'The ghosts got you!',
        subline: 'Final score: $s. The maze always wins… eventually.',
      );
    }
  }

  void _onPan(DragUpdateDetails d) {
    final dx = d.delta.dx, dy = d.delta.dy;
    if (dx.abs() < 2 && dy.abs() < 2) return;
    setState(() {
      _want = dx.abs() > dy.abs()
          ? Point(dx > 0 ? 1 : -1, 0)
          : Point(0, dy > 0 ? 1 : -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    return Column(
      children: [
        ScoreChips(players: widget.players, activeIndex: 0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('❤️ × $_lives', style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
              Text('MAZE ${_mazeIdx + 1} / 3', style: TextStyle(color: theme.muted, fontWeight: FontWeight.bold)),
              Text(_frightT > 0 ? '😱 HUNT!' : (_scatter ? '👻 scatter' : '👻 chase'),
                  style: TextStyle(color: theme.accent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onPanUpdate: _onPan,
            child: CustomPaint(
              painter: _MazePainter(
                maze: _maze,
                w: _w,
                h: _h,
                pellets: _pellets,
                powers: _powers,
                player: _pos,
                dir: _dir,
                mouth: _mouthT,
                ghosts: _ghosts,
                fruit: _fruit,
                fruitT: _fruitT,
                fright: _frightT,
                banner: _bannerT > 0 ? _banner : '',
                bg: theme.background,
                accent: theme.accent,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Swipe to steer • gobble everything!', style: TextStyle(color: theme.muted)),
        ),
      ],
    );
  }
}

class _MazePainter extends CustomPainter {
  final List<List<String>> maze;
  final int w, h;
  final Set<Point<int>> pellets, powers;
  final Point<double> player;
  final Point<int> dir;
  final double mouth;
  final List<_Ghost> ghosts;
  final Point<int>? fruit;
  final double fruitT, fright;
  final String banner;
  final Color bg, accent;

  _MazePainter({
    required this.maze,
    required this.w,
    required this.h,
    required this.pellets,
    required this.powers,
    required this.player,
    required this.dir,
    required this.mouth,
    required this.ghosts,
    required this.fruit,
    required this.fruitT,
    required this.fright,
    required this.banner,
    required this.bg,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final s = min(size.width / w, size.height / h);
    final ox = (size.width - s * w) / 2;
    final oy = (size.height - s * h) / 2;
    Offset cell(Point<int> p) => Offset(ox + p.x * s, oy + p.y * s);
    Offset center(Point<double> p) => Offset(ox + p.x * s, oy + p.y * s);

    // walls
    final wallPaint = Paint()..color = const Color(0xFF2B4BD8);
    final wallHi = Paint()..color = const Color(0xFF6B8CFF);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (maze[y][x] != '#') continue;
        final r = Rect.fromLTWH(ox + x * s + 1, oy + y * s + 1, s - 2, s - 2);
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.25)), wallPaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left + s * 0.18, r.top + s * 0.18, r.width - s * 0.36, r.height - s * 0.36),
            Radius.circular(s * 0.15),
          ),
          wallHi,
        );
      }
    }

    // pellets
    final pelletPaint = Paint()..color = const Color(0xFFFFD9A0);
    for (final p in pellets) {
      canvas.drawCircle(cell(p) + Offset(s / 2, s / 2), s * 0.09, pelletPaint);
    }
    final pulse = 0.5 + 0.5 * sin(DateTime.now().millisecondsSinceEpoch / 180);
    for (final p in powers) {
      canvas.drawCircle(cell(p) + Offset(s / 2, s / 2), s * (0.2 + 0.08 * pulse), pelletPaint);
    }

    // fruit
    if (fruit != null) {
      final c = cell(fruit!) + Offset(s / 2, s / 2);
      canvas.drawCircle(c + Offset(-s * 0.12, 0), s * 0.18, Paint()..color = Colors.red);
      canvas.drawCircle(c + Offset(s * 0.14, s * 0.08), s * 0.18, Paint()..color = Colors.redAccent);
      canvas.drawLine(c + Offset(-s * 0.12, -s * 0.15), c + Offset(s * 0.1, -s * 0.35),
          Paint()..color = Colors.green..strokeWidth = s * 0.07);
    }

    // player (muncher with chomping mouth)
    final pc = center(player);
    final pr = s * 0.42;
    final baseAng = dir.x == 1 ? 0.0 : dir.x == -1 ? pi : dir.y == 1 ? pi / 2 : dir.y == -1 ? -pi / 2 : 0.0;
    final chomp = 0.25 + 0.25 * sin(mouth);
    final path = Path()
      ..moveTo(pc.dx, pc.dy)
      ..addArc(Rect.fromCircle(center: pc, radius: pr), baseAng + chomp, 2 * pi - 2 * chomp)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD21F));
    canvas.drawCircle(pc + Offset(cos(baseAng + 1.2) * pr * 0.35, sin(baseAng + 1.2) * pr * 0.35 - pr * 0.25),
        pr * 0.12, Paint()..color = Colors.black);

    // ghosts
    for (final g in ghosts) {
      final gc = center(g.pos);
      final gr = s * 0.42;
      final bodyColor = g.eyes
          ? Colors.transparent
          : (g.frightened ? (fright < 2 && (fright * 5).floor().isEven ? Colors.white : const Color(0xFF2431FF)) : g.color);
      if (!g.eyes) {
        final body = Path()
          ..moveTo(gc.dx - gr, gc.dy + gr)
          ..lineTo(gc.dx - gr, gc.dy - gr * 0.2)
          ..arcTo(Rect.fromCircle(center: Offset(gc.dx, gc.dy - gr * 0.2), radius: gr), pi, -pi, false)
          ..lineTo(gc.dx + gr, gc.dy + gr);
        for (var i = 0; i < 4; i++) {
          final x0 = gc.dx - gr + i * (2 * gr / 4);
          body
            ..lineTo(x0 + gr / 4, gc.dy + gr * 0.55)
            ..lineTo(x0 + gr / 2, gc.dy + gr);
        }
        body.close();
        canvas.drawPath(body, Paint()..color = bodyColor);
      }
      // eyes
      final ex = gr * 0.32;
      final ey = -gr * 0.25;
      final look = g.frightened && !g.eyes ? const Offset(0, 0) : Offset(g.dir.x * gr * 0.12, g.dir.y * gr * 0.12);
      for (final side in [-1, 1]) {
        final ec = gc + Offset(side * ex, ey) + look;
        canvas.drawCircle(ec, gr * 0.22, Paint()..color = Colors.white);
        if (!g.frightened || g.eyes) {
          canvas.drawCircle(ec + look, gr * 0.11, Paint()..color = Colors.blue[900]!);
        }
      }
      if (g.frightened && !g.eyes) {
        canvas.drawLine(gc + Offset(-gr * 0.4, gr * 0.35), gc + Offset(gr * 0.4, gr * 0.35),
            Paint()..color = Colors.white..strokeWidth = 2);
      }
    }

    if (banner.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(text: banner, style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 32)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.42));
    }
  }

  @override
  bool shouldRepaint(covariant _MazePainter old) => true;
}
