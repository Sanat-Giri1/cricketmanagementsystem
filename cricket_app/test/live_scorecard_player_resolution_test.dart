import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/screens/live_scorecard_screen.dart';

void main() {
  group('resolveSelectedPlayerId', () {
    test('returns the selected player when it exists in the available list', () {
      final players = [
        {'player_id': 1, 'player_name': 'A'},
        {'player_id': 2, 'player_name': 'B'},
      ];

      expect(resolveSelectedPlayerId(2, players), 2);
    });

    test('falls back to the first available player when the selected id is invalid', () {
      final players = [
        {'player_id': 10, 'player_name': 'A'},
        {'player_id': 11, 'player_name': 'B'},
      ];

      expect(resolveSelectedPlayerId(99, players), 10);
    });

    test('returns null when no valid player is available', () {
      expect(resolveSelectedPlayerId(99, const []), isNull);
    });
  });
}
