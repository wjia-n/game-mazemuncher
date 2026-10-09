# Maze Muncher — Rules

_Authoritative rules. If the implementation conflicts with this document, fix the implementation._

## 1. Objective

Steer your muncher through the maze, gobble every pellet, and clear the maze
without getting caught by the ghosts. Power pellets turn the tables: hunt the
frightened ghosts for big points. Clear mazes to win the run.

## 2. Setup

- 1 player (renameable profile).
- Choose a mode (Campaign / Endless / Score Attack) and a difficulty
  (Chill / Classic / Nightmare).
- Campaign: maze 1 of 9. Endless / Score Attack: a generated maze.
- The muncher starts at its spawn pocket; ghosts start near the maze center.
- Lives: 4 (Chill) or 3 (Classic, Nightmare).

## 3. Turn order

Maze Muncher is real-time, not turn-based. Each run flows through
engine-owned phases: **countdown → playing → (dying | levelClear)* →
gameOver | victory**. Input is accepted only during countdown (pre-steered)
and playing; every other phase ignores it.

## 4. Legal moves

- Swipe up / down / left / right to steer. The wanted direction applies at
  the next tile center where the path is open (classic cornering).
- Reversing direction is always allowed, instantly.

## 5. Illegal moves

- Steering into a wall: the muncher stops at the tile center and waits.
- Steering during countdown/dying/levelClear/gameOver/victory/pause: ignored
  (no penalty, no state change).
- There are no invalid-move penalties; blocked input simply does nothing.

## 6. Captures

- A ghost touching the muncher (distance < 0.7 tiles) while NOT frightened
  captures it: lose one life, brief death animation, actors reset.
- A muncher touching a frightened ghost EATS it: 200 → 400 → 800 → 1600
  points for consecutive ghosts in one fright (chain resets when fright ends).
- Eaten ghosts become eyes, float home, and revive (frightened again only if
  fright time remains).

## 7. Special rules

- **Power pellets** (4 per maze): 50 points + frightens all ghosts for
  9s / 7s / 4s (Chill / Classic / Nightmare). Ghosts reverse on fright start.
- **Fruit** (cherry): appears at the muncher spawn after 70 and 140 pellets
  eaten in a maze, lasts 9 seconds, worth 100 × maze number.
- **Extra life**: every 10,000 points.
- **Scatter/chase**: ghosts alternate scatter (corners) and chase on a
  7/20/7/20/5/∞ second schedule, frozen during fright.
- **Ghost personalities**: Chaser targets you; Ambusher targets 4 tiles ahead
  of you; Shy chases when far (>8 tiles) and retreats to its corner when
  close; Wanderer picks randomly. Ghosts never reverse except on fright start.
- **Score Attack**: 120-second clock; clearing a maze adds +15 seconds.
  Clock hitting zero ends the run immediately.
- **Endless**: mazes generate forever; each new maze makes ghosts slightly
  faster (+0.15 tiles/s, capped) and shortens fright.

## 8. Scoring

- Pellet: 10 · Power pellet: 50 · Ghost: 200/400/800/1600 (chain)
- Fruit: 100 × maze number · Maze clear bonus: 250 × maze number
- Extra life thresholds do not add score.

## 9. Winning conditions

- Campaign: clear all 9 mazes → **victory**.
- Endless / Score Attack: no victory; the run ends on game over and the
  score is recorded against the mode's best.

## 10. Draw conditions

None — every run ends in victory or game over.

## 11. AI strategy

- Target selection per §7 personalities; at each tile decision the ghost
  takes the non-reversing exit minimizing Manhattan distance to its target.
- **Chill**: 35% random-turn error, slower ghosts, 3 ghosts.
- **Classic**: 15% random-turn error, 4 ghosts.
- **Nightmare**: 0% error (perfect play), fastest ghosts, short fright.

## 12. Edge cases

- Maze generation is guaranteed fully connected (perfect maze + loops), so
  every pellet is reachable and every maze is winnable.
- Pellets are cleared from the immediate spawn pocket.
- Fruit expiring, fright expiring mid-chase, and pause during any phase all
  resolve deterministically; the watchdog re-arms any phase timer lost to
  backgrounding.
- Lives can exceed the starting count via extra lives (HUD shows up to 9).
- Quitting mid-run discards the run (no stats recorded).

## 13. Test cases

1. Steering into a wall stops the muncher at the tile center (no clipping).
2. Eating all pellets triggers levelClear → next maze countdown.
3. Power pellet frightens ghosts; eating 2 ghosts in one fright scores
   200 then 400.
4. Ghost capture with 1 life left → game over; with lives left → countdown.
5. Score Attack clock reaching 0 ends the run immediately.
6. Campaign maze 9 clear → victory.
7. Pause during countdown/dying resumes the correct phase (watchdog).
8. Generated mazes: flood-fill from spawn reaches every pellet.
9. Extra life granted exactly when crossing each 10,000-point mark.
10. Nightmare ghosts never pick a random turn (0% error).
