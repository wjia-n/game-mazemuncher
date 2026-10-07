import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const MazeMuncherApp());

class MazeMuncherApp extends StatelessWidget {
  const MazeMuncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Maze Muncher',
      tagline: 'Gobble every pellet, dodge the ghosts, rule the maze!',
      emoji: '👻',
      slug: 'mazemuncher',
      howToPlay:
          '• Swipe to steer your muncher through the maze.\n• Eat every pellet to clear the maze — 3 mazes await.\n• Big glowing pellets turn the tables: hunt the ghosts!\n• Each ghost has its own personality. The orange one is… unpredictable.\n• You have 3 lives. Cherry bonus if you\'re quick!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => MazeMuncherScreen(players: players, callbacks: cb),
    );
  }
}
