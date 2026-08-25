import 'package:flutter_test/flutter_test.dart';
import 'package:showa_city/domain/city_game.dart';
import 'package:showa_city/domain/game_save.dart';

void main() {
  test('grid rejects duplicate and out-of-range placement', () {
    final game = CityGame(save: const GameSave(coins: 500));
    expect(game.place(CityGame.buildings.first, 0, 0), isTrue);
    expect(game.place(CityGame.buildings.first, 0, 0), isFalse);
    expect(game.place(CityGame.buildings.first, 9, 9), isFalse);
  });
  test('history reset keeps premium state and awards history points', () {
    final game = CityGame(
      save: const GameSave(
        coins: 5000,
        gems: 20,
        entitlements: ['permanent.boost'],
        buildings: [
          {'id': 'tower', 'population': 100},
        ],
      ),
    );
    game.historyReset();
    expect(game.save.gems, 20);
    expect(game.save.entitlements, contains('permanent.boost'));
    expect(game.save.historyPoints, 1);
  });
}
