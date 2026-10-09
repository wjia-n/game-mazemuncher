import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

// ---------------------------------------------------------------------------
// Maze Muncher engine: deterministic arcade maze-chase rules, state machine,
// and ghost AI. The engine OWNS every phase and transition; the UI only
// renders and forwards input. A watchdog recovers any phase found without a
// live timer, so stuck states are impossible by construction.
// ---------------------------------------------------------------------------

/// Phases owned entirely by the engine.
enum MazePhase {
  idle, // no run active
  countdown, // "READY!" — steering pre-queues, timer starts play
  playing, // live gameplay on the engine ticker
  dying, // caught animation — timer resolves to countdown or game over
  levelClear, // maze cleared banner — timer advances to the next maze
  gameOver, // terminal: out of lives / time up
  victory, // terminal: campaign completed
}

enum GameMode { campaign, endless, scoreAttack }

enum MazeDifficulty { chill, classic, nightmare }

/// Difficulty tuning: speed/complexity scaling (RULES.md §11).
class DifficultyTuning {
  final double playerSpeed; // tiles per second
  final double ghostSpeed;
  final double frightSecs;
  final double aiError; // chance a ghost picks a random turn (0 = perfect)
  final int lives;
  final int ghostCount;
  const DifficultyTuning({
    required this.playerSpeed,
    required this.ghostSpeed,
    required this.frightSecs,
    required this.aiError,
    required this.lives,
    required this.ghostCount,
  });
}

const difficultyTunings = {
  MazeDifficulty.chill: DifficultyTuning(
    playerSpeed: 7.6,
    ghostSpeed: 4.9,
    frightSecs: 9.0,
    aiError: 0.35,
    lives: 4,
    ghostCount: 3,
  ),
  MazeDifficulty.classic: DifficultyTuning(
    playerSpeed: 7.4,
    ghostSpeed: 6.4,
    frightSecs: 7.0,
    aiError: 0.15,
    lives: 3,
    ghostCount: 4,
  ),
  MazeDifficulty.nightmare: DifficultyTuning(
    playerSpeed: 7.2,
    ghostSpeed: 7.7,
    frightSecs: 4.0,
    aiError: 0.0,
    lives: 3,
    ghostCount: 4,
  ),
};

/// Curated campaign mazes 1–3 (classic layouts, kept from the original game).
const _curatedMaps = [
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
    "#....#...#...#...#",
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

/// Campaign: 9 mazes. 1–3 curated, 4–9 generated (deterministic seeds,
/// growing size and complexity).
const campaignMazeCount = 9;

List<String> campaignMaze(int index, Random rand) {
  if (index < _curatedMaps.length) return _curatedMaps[index];
  final size = switch (index) {
    3 => [19, 15],
    4 => [21, 15],
    5 => [21, 17],
    6 => [23, 17],
    7 => [23, 19],
    _ => [25, 19],
  };
  return generateMaze(size[0], size[1], Random(1000 + index));
}

/// Perfect-maze generator (recursive backtracker) with a few loops knocked
/// through so routes aren't single-file. Guaranteed fully connected, so
/// every pellet is reachable and every maze is winnable.
@visibleForTesting
List<String> generateMaze(int w, int h, Random rand) {
  assert(w.isOdd && h.isOdd && w >= 11 && h >= 9);
  final g = List.generate(h, (_) => List.filled(w, '#'));
  final stack = <Point<int>>[const Point(1, 1)];
  g[1][1] = ' ';
  const dirs = [Point(2, 0), Point(-2, 0), Point(0, 2), Point(0, -2)];
  while (stack.isNotEmpty) {
    final p = stack.last;
    final options = <Point<int>>[];
    for (final d in dirs) {
      final n = Point(p.x + d.x, p.y + d.y);
      if (n.x > 0 && n.y > 0 && n.x < w - 1 && n.y < h - 1 && g[n.y][n.x] == '#') {
        options.add(d);
      }
    }
    if (options.isEmpty) {
      stack.removeLast();
    } else {
      final d = options[rand.nextInt(options.length)];
      g[p.y + d.y ~/ 2][p.x + d.x ~/ 2] = ' ';
      final n = Point(p.x + d.x, p.y + d.y);
      g[n.y][n.x] = ' ';
      stack.add(n);
    }
  }
  // Knock loops: open some walls between two open cells (~10% of interior).
  var loops = (w * h * 0.10).round();
  var guard = loops * 20;
  while (loops > 0 && guard-- > 0) {
    final x = 1 + rand.nextInt(w - 2);
    final y = 1 + rand.nextInt(h - 2);
    if (g[y][x] != '#') continue;
    final horiz = g[y][x - 1] == ' ' && g[y][x + 1] == ' ';
    final vert = g[y - 1][x] == ' ' && g[y + 1][x] == ' ';
    if (horiz || vert) {
      g[y][x] = ' ';
      loops--;
    }
  }
  return [for (final row in g) row.join()];
}

class Ghost {
  Point<double> pos;
  Point<int> dir;
  final int kind; // 0 chaser, 1 ambusher, 2 shy, 3 random
  bool frightened = false;
  bool eyes = false;
  Ghost(this.pos, this.dir, this.kind);
}

/// Floating score popup (visual only).
class ScorePop {
  final Point<double> pos; // tile units
  final String text;
  final DateTime born = DateTime.now();
  ScorePop(this.pos, this.text);
  double get ageSecs => DateTime.now().difference(born).inMilliseconds / 1000;
}

enum MazeEvent {
  gameStart,
  munch,
  power,
  eatGhost,
  fruit,
  death,
  extraLife,
  levelClear,
  gameOver,
  victory,
  invalid,
}

class MazeEngine extends ChangeNotifier {
  final Random _rand;
  late DifficultyTuning _tune;

  GameMode mode = GameMode.campaign;
  MazeDifficulty difficulty = MazeDifficulty.classic;

  // Phase state — owned by the engine, never the UI.
  MazePhase phase = MazePhase.idle;
  bool paused = false;

  // Run state.
  int score = 0;
  int lives = 3;
  int mazeNumber = 1; // 1-based display
  int mazeIndex = 0; // 0-based campaign index
  int endlessDepth = 0; // endless maze counter
  double timeLeft = 0; // score attack only
  int pelletsEatenRun = 0;
  int ghostsEatenRun = 0;
  int _nextExtraLifeAt = 10000;

  // Maze state.
  int w = 19, h = 15;
  List<List<String>> maze = [];
  final Set<Point<int>> pellets = {};
  final Set<Point<int>> powers = {};
  Point<int> playerStart = const Point(9, 13);
  Point<int> ghostHome = const Point(9, 7);

  // Actors.
  Point<double> pos = const Point(9.5, 13.5);
  Point<int> dir = const Point(0, 0);
  Point<int> want = const Point(-1, 0);
  final List<Ghost> ghosts = [];
  double frightT = 0;
  double mouthT = 0;
  double deathT = 0; // 0..1 death animation progress
  int ghostChain = 0;

  // Scatter/chase schedule.
  double _modeT = 0;
  int _modeIdx = 0;
  static const _modeDur = [7.0, 20.0, 7.0, 20.0, 5.0, 1e9];

  // Fruit.
  Point<int>? fruit;
  double _fruitT = 0;
  int _fruitAt70 = 0, _fruitAt140 = 0;
  int _eatenThisMaze = 0;

  // Banner + popups (visual).
  String banner = '';
  double bannerT = 0;
  final List<ScorePop> pops = [];

  /// UI hook for sounds / haptics. Set by the screen.
  void Function(MazeEvent event)? onEvent;

  Ticker? _ticker;
  Duration _last = Duration.zero;
  Timer? _phaseTimer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;

  static const _countdownMs = 1600;
  static const _dyingMs = 1300;
  static const _clearMs = 1700;

  MazeEngine({Random? rand}) : _rand = rand ?? Random() {
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
  }

  bool get playing => phase == MazePhase.playing;
  bool get isTerminal =>
      phase == MazePhase.gameOver || phase == MazePhase.victory;
  bool get isIdle => phase == MazePhase.idle;

  int get pelletsLeft => pellets.length + powers.length;

  String get hudLevel {
    switch (mode) {
      case GameMode.campaign:
        return 'MAZE $mazeNumber/$campaignMazeCount';
      case GameMode.endless:
        return 'MAZE $mazeNumber · ENDLESS';
      case GameMode.scoreAttack:
        final s = timeLeft.ceil().clamp(0, 999);
        return '⏱ ${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.dispose();
    _phaseTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ run control
  void startRun({required GameMode m, required MazeDifficulty d}) {
    _cancelTimers();
    mode = m;
    difficulty = d;
    _tune = difficultyTunings[d]!;
    score = 0;
    lives = _tune.lives;
    mazeIndex = 0;
    mazeNumber = 1;
    endlessDepth = 0;
    timeLeft = 120;
    pelletsEatenRun = 0;
    ghostsEatenRun = 0;
    _nextExtraLifeAt = 10000;
    paused = false;
    _loadMaze(campaignMaze(0, _rand));
    _beginCountdown(first: true);
  }

  void restartRun() {
    startRun(mode: mode, difficulty: difficulty);
  }

  /// Leave the run entirely (back to menu). Engine goes idle; timers stop.
  void quitToMenu() {
    _cancelTimers();
    phase = MazePhase.idle;
    paused = false;
    notifyListeners();
  }

  void _cancelTimers() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }

  /// Single phase-transition timer. Any new phase cancels the old one —
  /// there is exactly one pending transition at a time.
  void _armPhase(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _phaseTimer?.cancel();
    _phaseTimer = Timer(d, () {
      _phaseTimer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze ticker AND phase timer. Resume re-arms via _recover().
  void setPaused(bool v) {
    if (paused == v || _disposed || isTerminal || isIdle) return;
    paused = v;
    if (v) {
      _ticker?.stop();
      _phaseTimer?.cancel();
      _phaseTimer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, or the
  /// ticker stops mid-game, recover the phase. Stuck states impossible by
  /// construction. Respects [paused].
  void _recover() {
    if (_disposed || paused || isTerminal || isIdle) return;
    if (phase == MazePhase.playing) {
      if (_ticker == null || !_ticker!.isActive) _startTicker();
      return;
    }
    if (_phaseTimer != null) return; // a transition is pending — healthy
    switch (phase) {
      case MazePhase.countdown:
        // Countdown lost its timer (e.g. after backgrounding): short re-arm.
        _armPhase(const Duration(milliseconds: 800), _beginPlay);
        break;
      case MazePhase.dying:
        _armPhase(const Duration(milliseconds: 600), _afterDying);
        break;
      case MazePhase.levelClear:
        _armPhase(const Duration(milliseconds: 800), _advanceLevel);
        break;
      default:
        break;
    }
  }

  void _beginCountdown({bool first = false}) {
    phase = MazePhase.countdown;
    banner = first ? 'READY!' : 'READY!';
    bannerT = 2.0;
    notifyListeners();
    onEvent?.call(MazeEvent.gameStart);
    _armPhase(const Duration(milliseconds: _countdownMs), _beginPlay);
  }

  void _beginPlay() {
    if (isTerminal || _disposed || paused) return;
    phase = MazePhase.playing;
    banner = '';
    bannerT = 0;
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    if (_disposed || paused || isTerminal) return;
    _ticker?.dispose();
    _last = Duration.zero;
    _ticker = Ticker(_tick)..start();
  }

  // ----------------------------------------------------------------- input
  /// Steering is accepted during countdown (pre-queued) and playing.
  /// In any other phase it is ignored — the engine simply has no use for it.
  void steer(Point<int> d) {
    if (d.x == 0 && d.y == 0) return;
    if (phase == MazePhase.playing || phase == MazePhase.countdown) {
      want = d;
    }
  }

  // ------------------------------------------------------------------ maze
  void _loadMaze(List<String> raw) {
    h = raw.length;
    w = raw[0].length;
    maze = [for (final row in raw) row.split('')];
    pellets.clear();
    powers.clear();
    playerStart = Point(w ~/ 2, h - 2);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final c = maze[y][x];
        if (c == '.') {
          pellets.add(Point(x, y));
          maze[y][x] = ' ';
        } else if (c == 'o') {
          powers.add(Point(x, y));
          maze[y][x] = ' ';
        } else if (c == 'P') {
          playerStart = Point(x, y);
          maze[y][x] = ' ';
        }
      }
    }
    if (pellets.isEmpty && powers.isEmpty) {
      // Generated mazes have no markers: pellet on every open cell.
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (maze[y][x] == ' ') pellets.add(Point(x, y));
        }
      }
    }
    // Power pellets: 4, near the corners (nearest open cell).
    if (powers.isEmpty) {
      const corners = [Point(1, 1), Point(-2, 1), Point(1, -2), Point(-2, -2)];
      for (final c in corners) {
        final cx = c.x < 0 ? w + c.x : c.x;
        final cy = c.y < 0 ? h + c.y : c.y;
        final spot = _nearestOpen(Point(cx, cy), playerStart);
        if (spot != null) {
          powers.add(spot);
          pellets.remove(spot);
        }
      }
    }
    // Keep pellets away from the spawn pocket so the player isn't fed.
    pellets.removeWhere(
        (p) => (p.x - playerStart.x).abs() + (p.y - playerStart.y).abs() <= 1);
    ghostHome = _nearestOpen(Point(w ~/ 2, h ~/ 2), playerStart) ??
        Point(w ~/ 2, h ~/ 2);
    _eatenThisMaze = 0;
    _fruitAt70 = 0;
    _fruitAt140 = 0;
    fruit = null;
    _resetActors();
  }

  Point<int>? _nearestOpen(Point<int> near, Point<int> avoid) {
    Point<int>? best;
    var bestD = 1 << 30;
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        if (maze[y][x] != ' ') continue;
        if (x == avoid.x && y == avoid.y) continue;
        final d = (x - near.x).abs() + (y - near.y).abs();
        if (d < bestD) {
          bestD = d;
          best = Point(x, y);
        }
      }
    }
    return best;
  }

  void _resetActors() {
    pos = Point(playerStart.x + 0.5, playerStart.y + 0.5);
    dir = const Point(0, 0);
    want = const Point(-1, 0);
    ghosts.clear();
    // Ghost spawn: open cells around the ghost home, spread out.
    final spots = <Point<int>>[];
    for (var r = 0; r <= 3 && spots.length < _tune.ghostCount; r++) {
      for (var y = ghostHome.y - r; y <= ghostHome.y + r; y++) {
        for (var x = ghostHome.x - r; x <= ghostHome.x + r; x++) {
          final p = Point(x, y);
          if (x > 0 &&
              y > 0 &&
              x < w - 1 &&
              y < h - 1 &&
              maze[y][x] == ' ' &&
              !spots.contains(p) &&
              p != playerStart) {
            spots.add(p);
            if (spots.length >= _tune.ghostCount) break;
          }
        }
        if (spots.length >= _tune.ghostCount) break;
      }
    }
    const dirs = [Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1)];
    for (var i = 0; i < _tune.ghostCount && i < spots.length; i++) {
      final s = spots[i];
      ghosts.add(Ghost(Point(s.x + 0.5, s.y + 0.5), dirs[i % 4], i % 4));
    }
    frightT = 0;
    ghostChain = 0;
    deathT = 0;
    _modeIdx = 0;
    _modeT = 0;
  }

  bool _wall(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return true;
    return maze[y][x] == '#';
  }

  bool _canGo(Point<int> t, Point<int> d) => !_wall(t.x + d.x, t.y + d.y);

  // ------------------------------------------------------------------ tick
  void _tick(Duration now) {
    if (_disposed || paused) {
      _last = now;
      return;
    }
    final dt = min((now - _last).inMicroseconds / 1e6, 1 / 30);
    _last = now;
    if (dt <= 0) return;
    // Death animation runs on the engine ticker (not a UI timer): the
    // phase timer fires _afterDying, the ticker drives deathT 0→1.
    if (phase == MazePhase.dying) {
      deathT = min(1.0, deathT + dt / (_dyingMs / 1000));
      if (mounted) notifyListeners();
      return;
    }
    if (phase != MazePhase.playing) return;
    mouthT += dt * 10;
    bannerT = max(0, bannerT - dt);
    pops.removeWhere((p) => p.ageSecs > 1.1);

    // Score-attack clock.
    if (mode == GameMode.scoreAttack) {
      timeLeft -= dt;
      if (timeLeft <= 0) {
        timeLeft = 0;
        _finish(false, timeUp: true);
        return;
      }
    }

    // Mode schedule (scatter/chase), frozen while frightened.
    if (frightT <= 0) {
      _modeT += dt;
      if (_modeT >= _modeDur[_modeIdx]) {
        _modeT = 0;
        _modeIdx = min(_modeIdx + 1, _modeDur.length - 1);
      }
    } else {
      frightT -= dt;
      if (frightT <= 0) {
        for (final g in ghosts) {
          g.frightened = false;
        }
        ghostChain = 0;
      }
    }

    if (fruit != null) {
      _fruitT -= dt;
      if (_fruitT <= 0) fruit = null;
    }

    _movePlayer(dt);
    for (final g in ghosts) {
      _moveGhost(g, dt);
    }
    _checkCollisions();
    if (mounted) notifyListeners();
  }

  bool get mounted => !_disposed;

  Point<int> _tileOf(Point<double> p) => Point(p.x.floor(), p.y.floor());

  void _movePlayer(double dt) {
    var remaining = _tune.playerSpeed * dt;
    var guard = 0;
    while (remaining > 1e-9 && guard++ < 8) {
      if (dir.x == 0 && dir.y == 0) {
        if (_canGo(_tileOf(pos), want)) {
          dir = want;
        } else {
          break;
        }
      }
      final tile = _tileOf(pos);
      final nt = Point(tile.x + dir.x, tile.y + dir.y);
      if (_wall(nt.x, nt.y)) {
        pos = Point(tile.x + 0.5, tile.y + 0.5);
        dir = const Point(0, 0);
        break;
      }
      final center = Point(nt.x + 0.5, nt.y + 0.5);
      final dist = dir.x * (center.x - pos.x) + dir.y * (center.y - pos.y);
      if (dist <= remaining) {
        pos = center;
        remaining -= dist;
        _onArrivePlayer(nt);
        if (phase != MazePhase.playing) return; // level cleared mid-move
        if (_canGo(nt, want)) {
          dir = want;
        } else if (!_canGo(nt, dir)) {
          dir = const Point(0, 0);
        }
      } else {
        pos = Point(pos.x + dir.x * remaining, pos.y + dir.y * remaining);
        remaining = 0;
      }
    }
  }

  void _onArrivePlayer(Point<int> t) {
    if (pellets.remove(t)) {
      _addScore(10, t, null);
      pelletsEatenRun++;
      _eatenThisMaze++;
      onEvent?.call(MazeEvent.munch);
      _maybeFruit();
      _checkExtraLife();
      _checkWin();
    } else if (powers.remove(t)) {
      _addScore(50, t, null);
      pelletsEatenRun++;
      _eatenThisMaze++;
      frightT = _tune.frightSecs;
      ghostChain = 0;
      for (final g in ghosts) {
        if (!g.eyes) {
          g.frightened = true;
          // Classic: ghosts reverse when frightened.
          g.dir = Point(-g.dir.x, -g.dir.y);
        }
      }
      onEvent?.call(MazeEvent.power);
      _maybeFruit();
      _checkExtraLife();
      _checkWin();
    }
    if (fruit != null && t == fruit) {
      final pts = 100 * (mazeNumber);
      _addScore(pts, t, 'FRUIT +$pts');
      fruit = null;
      onEvent?.call(MazeEvent.fruit);
    }
  }

  void _maybeFruit() {
    if (_fruitAt70 == 0 && _eatenThisMaze >= 70) {
      _fruitAt70 = 1;
      fruit = playerStart;
      _fruitT = 9;
    } else if (_fruitAt140 == 0 && _eatenThisMaze >= 140) {
      _fruitAt140 = 1;
      fruit = playerStart;
      _fruitT = 9;
    }
  }

  void _checkExtraLife() {
    if (score >= _nextExtraLifeAt) {
      _nextExtraLifeAt += 10000;
      lives++;
      banner = 'EXTRA LIFE!';
      bannerT = 1.6;
      onEvent?.call(MazeEvent.extraLife);
    }
  }

  void _addScore(int pts, Point<int>? at, String? label) {
    score += pts;
    if (at != null) {
      pops.add(ScorePop(
          Point(at.x + 0.5, at.y + 0.5), label ?? '+$pts'));
    }
  }

  void _checkWin() {
    if (pellets.isEmpty && powers.isEmpty && phase == MazePhase.playing) {
      final bonus = 250 * mazeNumber;
      score += bonus;
      phase = MazePhase.levelClear;
      banner = 'MAZE CLEAR!  +$bonus';
      bannerT = 2.0;
      _ticker?.stop();
      notifyListeners();
      onEvent?.call(MazeEvent.levelClear);
      _armPhase(const Duration(milliseconds: _clearMs), _advanceLevel);
    }
  }

  void _advanceLevel() {
    if (isTerminal || _disposed || paused) return;
    switch (mode) {
      case GameMode.campaign:
        if (mazeIndex + 1 >= campaignMazeCount) {
          _finish(true);
          return;
        }
        mazeIndex++;
        mazeNumber = mazeIndex + 1;
        _loadMaze(campaignMaze(mazeIndex, _rand));
        break;
      case GameMode.endless:
        endlessDepth++;
        mazeNumber = endlessDepth + 1;
        // Endless ramps: ghosts get a touch faster each maze.
        final extra = min(endlessDepth * 0.15, 1.5);
        _tune = DifficultyTuning(
          playerSpeed: _tune.playerSpeed,
          ghostSpeed: _tune.ghostSpeed + extra,
          frightSecs: max(3.0, _tune.frightSecs - endlessDepth * 0.2),
          aiError: max(0.0, _tune.aiError - endlessDepth * 0.02),
          lives: _tune.lives,
          ghostCount: _tune.ghostCount,
        );
        _loadMaze(generateMaze(
            min(19 + endlessDepth * 2, 25), 15, Random()));
        break;
      case GameMode.scoreAttack:
        mazeNumber++;
        timeLeft += 15; // clear bonus time
        banner = '+15s!';
        _loadMaze(generateMaze(19, 15, Random()));
    }
    _beginCountdown();
  }

  // -------------------------------------------------------------- ghost AI
  bool get _scatter => _modeIdx.isEven;
  static const _corners = [
    Point(1, 1),
    Point(-2, 1),
    Point(1, -2),
    Point(-2, -2)
  ];

  Point<int> _ghostTarget(Ghost g) {
    final pt = _tileOf(pos);
    if (g.eyes) return ghostHome;
    if (g.frightened) return Point(_rand.nextInt(w), _rand.nextInt(h));
    if (_scatter) {
      final c = _corners[g.kind % 4];
      return Point(c.x < 0 ? w + c.x : c.x, c.y < 0 ? h + c.y : c.y);
    }
    switch (g.kind) {
      case 0: // chaser: straight at the muncher
        return pt;
      case 1: // ambusher: 4 tiles ahead of the muncher
        return Point(pt.x + dir.x * 4, pt.y + dir.y * 4);
      case 2: // shy: chases when far, retreats when close
        final d = (pt.x - _tileOf(g.pos).x).abs() +
            (pt.y - _tileOf(g.pos).y).abs();
        if (d > 8) return pt;
        final c = _corners[g.kind % 4];
        return Point(c.x < 0 ? w + c.x : c.x, c.y < 0 ? h + c.y : c.y);
      default: // random: wanders
        return Point(_rand.nextInt(w), _rand.nextInt(h));
    }
  }

  void _moveGhost(Ghost g, double dt) {
    final speed = g.eyes ? 11.0 : (g.frightened ? 4.4 : _tune.ghostSpeed);
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
        if (g.eyes && nt == ghostHome) {
          g.eyes = false;
          g.frightened = frightT > 0;
        }
        // Choose next direction (no reversing, classic rule).
        final rev = Point(-g.dir.x, -g.dir.y);
        final options = dirs.where((d) => d != rev && _canGo(nt, d)).toList();
        if (options.isEmpty) {
          final back = dirs.where((d) => _canGo(nt, d)).toList();
          g.dir = back.isEmpty
              ? const Point(0, 0)
              : back[_rand.nextInt(back.length)];
        } else if (options.length == 1 ||
            (g.kind == 3 && !g.eyes) ||
            _rand.nextDouble() < _tune.aiError) {
          g.dir = options[_rand.nextInt(options.length)];
        } else {
          final target = _ghostTarget(g);
          options.sort((a, b) {
            final da = (nt.x + a.x - target.x).abs() +
                (nt.y + a.y - target.y).abs();
            final db = (nt.x + b.x - target.x).abs() +
                (nt.y + b.y - target.y).abs();
            return da.compareTo(db);
          });
          g.dir = options.first;
        }
      } else {
        g.pos = Point(g.pos.x + g.dir.x * remaining,
            g.pos.y + g.dir.y * remaining);
        remaining = 0;
      }
    }
  }

  void _checkCollisions() {
    for (final g in ghosts) {
      final d = (g.pos.x - pos.x).abs() + (g.pos.y - pos.y).abs();
      if (d < 0.7 && !g.eyes) {
        if (g.frightened) {
          g.frightened = false;
          g.eyes = true;
          final pts = 200 << ghostChain;
          ghostChain = min(ghostChain + 1, 3);
          ghostsEatenRun++;
          _addScore(pts, _tileOf(g.pos), '+$pts');
          onEvent?.call(MazeEvent.eatGhost);
        } else {
          _caught();
          return;
        }
      }
    }
  }

  void _caught() {
    lives--;
    phase = MazePhase.dying;
    deathT = 0;
    banner = lives > 0 ? 'OUCH!' : '';
    bannerT = 1.2;
    // Ticker keeps running so the engine drives the death animation
    // (deathT 0→1); _afterDying is armed on the single phase timer.
    notifyListeners();
    onEvent?.call(MazeEvent.death);
    _armPhase(const Duration(milliseconds: _dyingMs), _afterDying);
  }

  void _afterDying() {
    if (isTerminal || _disposed || paused) return;
    if (lives <= 0) {
      _finish(false);
    } else {
      _resetActors();
      _beginCountdown();
    }
  }

  void _finish(bool won, {bool timeUp = false}) {
    _cancelTimers();
    phase = won ? MazePhase.victory : MazePhase.gameOver;
    banner = won
        ? 'YOU RULE THE MAZE!'
        : (timeUp ? "TIME'S UP!" : 'GAME OVER');
    bannerT = 3.0;
    notifyListeners();
    onEvent?.call(won ? MazeEvent.victory : MazeEvent.gameOver);
  }
}
