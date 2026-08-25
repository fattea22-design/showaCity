import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:showa_city/data/game_save_repository.dart';
import 'package:showa_city/domain/game_save.dart';

void main() {
  test('round trips the complete save schema', () {
    final save = GameSave(
      coins: 120,
      gems: 8,
      buildings: const [
        {'id': 'shop', 'level': 2},
      ],
      areas: const ['a1'],
      era: 'heisei',
      historyPoints: 3,
      lastActiveAt: DateTime.utc(2026, 1, 1),
      processedTransactions: const ['tx-1'],
      entitlements: const ['permanent.boost'],
    );
    final restored = GameSave.decode(save.encode());
    expect(restored.coins, 120);
    expect(restored.buildings.single['level'], 2);
    expect(restored.entitlements, contains('permanent.boost'));
  });

  test('migrates an old save without deleting purchase data', () {
    final restored = GameSave.decode(
      '{"schemaVersion":0,"coins":5,"gems":2,"entitlements":["retro.landmark"]}',
    );
    expect(restored.schemaVersion, GameSave.currentSchemaVersion);
    expect(restored.gems, 2);
    expect(restored.entitlements, contains('retro.landmark'));
  });

  test('corrupt or future saves safely fall back to a new save', () {
    expect(GameSave.safeDecode('{broken').coins, 0);
    expect(GameSave.safeDecode('{"schemaVersion":99}').era, 'showa');
  });

  test('repository writes and reads a save', () async {
    final directory = await Directory.systemTemp.createTemp('showa_city_save_');
    addTearDown(() => directory.delete(recursive: true));
    final repository = GameSaveRepository(File('${directory.path}/save.json'));
    await repository.save(const GameSave(coins: 42));
    expect((await repository.load()).coins, 42);
  });
}
