import 'package:flutter_test/flutter_test.dart';
import 'package:mazemuncher/services/settings_service.dart';

void main() {
  group('player name persistence (single JSON string)', () {
    test('encode/decode round-trips the name', () {
      const name = 'Ghost Hunter 99';
      expect(MazeSettings.decodePlayerName(
          MazeSettings.encodePlayerName(name)), name);
    });

    test('empty name falls back to the default', () {
      expect(
          MazeSettings.decodePlayerName(MazeSettings.encodePlayerName('   ')),
          MazeSettings.defaultName);
    });

    test('corrupt JSON falls back to the default', () {
      expect(MazeSettings.decodePlayerName('not-json{{{'),
          MazeSettings.defaultName);
      expect(MazeSettings.decodePlayerName(null), MazeSettings.defaultName);
      expect(MazeSettings.decodePlayerName('["a","b"]'),
          MazeSettings.defaultName);
    });

    test('unicode names survive', () {
      const name = 'مینچر 👻';
      expect(MazeSettings.decodePlayerName(
          MazeSettings.encodePlayerName(name)), name);
    });
  });
}
