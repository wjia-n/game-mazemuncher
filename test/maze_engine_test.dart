import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazemuncher/engine/maze_engine.dart';

void main() {
  group('generateMaze', () {
    test('is fully connected: every open cell reachable from spawn', () {
      for (var seed = 1; seed <= 10; seed++) {
        final raw = generateMaze(19, 15, Random(seed));
        final h = raw.length, w = raw[0].length;
        expect(w.isOdd, isTrue);
        expect(h.isOdd, isTrue);
        // Border walls.
        for (var x = 0; x < w; x++) {
          expect(raw[0][x], '#');
          expect(raw[h - 1][x], '#');
        }
        for (var y = 0; y < h; y++) {
          expect(raw[y][0], '#');
          expect(raw[y][w - 1], '#');
        }
        final open = <Point<int>>{};
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (raw[y][x] != '#') open.add(Point(x, y));
          }
        }
        // Flood fill from the first open cell.
        final seen = <Point<int>>{open.first};
        final q = <Point<int>>[open.first];
        const dirs = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
        while (q.isNotEmpty) {
          final p = q.removeLast();
          for (final d in dirs) {
            final n = Point(p.x + d.x, p.y + d.y);
            if (open.contains(n) && seen.add(n)) q.add(n);
          }
        }
        expect(seen.length, open.length,
            reason: 'seed $seed: unreachable open cells');
      }
    });

    test('deterministic for the same seed', () {
      expect(generateMaze(19, 15, Random(42)),
          generateMaze(19, 15, Random(42)));
    });
  });

  group('campaignMaze', () {
    test('has 9 valid mazes', () {
      for (var i = 0; i < campaignMazeCount; i++) {
        final raw = campaignMaze(i, Random(7));
        expect(raw, isNotEmpty);
        final w = raw[0].length;
        for (final row in raw) {
          expect(row.length, w);
        }
        expect(raw[0].split('').every((c) => c == '#'), isTrue);
      }
    });
  });

  group('MazeEngine state machine', () {
    test('starts idle; steer is ignored when idle', () {
      final e = MazeEngine(rand: Random(1));
      expect(e.phase, MazePhase.idle);
      e.steer(const Point(1, 0)); // must not throw, must not queue
      expect(e.want, const Point(-1, 0));
      e.dispose();
    });

    test('startRun enters countdown with difficulty lives', () {
      final e = MazeEngine(rand: Random(1));
      e.startRun(mode: GameMode.campaign, difficulty: MazeDifficulty.chill);
      expect(e.phase, MazePhase.countdown);
      expect(e.lives, 4);
      expect(e.score, 0);
      expect(e.pelletsLeft, greaterThan(0));
      e.dispose();
    });

    test('nightmare uses 3 lives and faster ghosts', () {
      final e = MazeEngine(rand: Random(1));
      e.startRun(mode: GameMode.campaign, difficulty: MazeDifficulty.nightmare);
      expect(e.lives, 3);
      expect(difficultyTunings[MazeDifficulty.nightmare]!.ghostSpeed,
          greaterThan(difficultyTunings[MazeDifficulty.chill]!.ghostSpeed));
      expect(difficultyTunings[MazeDifficulty.nightmare]!.aiError, 0.0);
      e.dispose();
    });

    test('steer queues during countdown', () {
      final e = MazeEngine(rand: Random(1));
      e.startRun(mode: GameMode.endless, difficulty: MazeDifficulty.classic);
      e.steer(const Point(0, 1));
      expect(e.want, const Point(0, 1));
      e.dispose();
    });

    test('score attack starts a 120s clock', () {
      final e = MazeEngine(rand: Random(1));
      e.startRun(
          mode: GameMode.scoreAttack, difficulty: MazeDifficulty.classic);
      expect(e.timeLeft, 120);
      e.dispose();
    });

    test('quitToMenu returns to idle', () {
      final e = MazeEngine(rand: Random(1));
      e.startRun(mode: GameMode.campaign, difficulty: MazeDifficulty.classic);
      e.quitToMenu();
      expect(e.phase, MazePhase.idle);
      e.dispose();
    });

    test('restartRun resets score and lives', () {
      final e = MazeEngine(rand: Random(1));
      e.startRun(mode: GameMode.campaign, difficulty: MazeDifficulty.classic);
      e.score = 1234;
      e.lives = 1;
      e.restartRun();
      expect(e.score, 0);
      expect(e.lives, 3);
      expect(e.phase, MazePhase.countdown);
      e.dispose();
    });
  });
}
