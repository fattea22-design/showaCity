import 'game_domain.dart';
import 'game_save.dart';

class CityGame {
  CityGame({GameSave? save}) : _save = save ?? const GameSave();
  GameSave _save;
  final economy = const EconomyCalculator(BalanceConfig());
  final idle = const IdleIncomeCalculator();
  static const width = 6;
  static const height = 5;
  static const buildings = <BuildingDefinition>[
    BuildingDefinition(
      id: 'dagashiya',
      era: Era.showa,
      category: BuildingCategory.commercial,
      baseCost: 100,
      baseIncome: 60,
      basePopulation: 0,
    ),
    BuildingDefinition(
      id: 'nagaya',
      era: Era.showa,
      category: BuildingCategory.residential,
      baseCost: 150,
      baseIncome: 0,
      basePopulation: 10,
    ),
    BuildingDefinition(
      id: 'kissa',
      era: Era.showa,
      category: BuildingCategory.commercial,
      baseCost: 250,
      baseIncome: 120,
      basePopulation: 0,
    ),
    BuildingDefinition(
      id: 'karaoke',
      era: Era.heisei,
      category: BuildingCategory.commercial,
      baseCost: 800,
      baseIncome: 400,
      basePopulation: 0,
    ),
    BuildingDefinition(
      id: 'tower',
      era: Era.reiwa,
      category: BuildingCategory.residential,
      baseCost: 2500,
      baseIncome: 0,
      basePopulation: 80,
    ),
  ];
  GameSave get save => _save;
  Era get era => Era.values.firstWhere(
    (e) => e.name == _save.era,
    orElse: () => Era.showa,
  );
  int get population =>
      _save.buildings.fold(0, (sum, b) => sum + (b['population'] as int? ?? 0));
  int get incomePerHour =>
      _save.buildings.fold(0, (sum, b) => sum + (b['income'] as int? ?? 0));
  bool canPlace(int x, int y) =>
      x >= 0 &&
      x < width &&
      y >= 0 &&
      y < height &&
      !_save.buildings.any((b) => b['x'] == x && b['y'] == y);
  bool place(BuildingDefinition d, int x, int y) {
    if (!canPlace(x, y) ||
        d.era.index > era.index ||
        _save.coins < d.baseCost) {
      return false;
    }
    final item = {
      'id': d.id,
      'x': x,
      'y': y,
      'level': 1,
      'income': economy.incomePerHour(d, 1),
      'population': economy.population(d, 1),
    };
    _save = GameSave(
      coins: _save.coins - d.baseCost,
      gems: _save.gems,
      buildings: [..._save.buildings, item],
      era: _save.era,
      missions: [
        ..._save.missions,
        if (_save.missions.isEmpty) 'first_building',
      ],
      achievements: _save.achievements,
      historyPoints: _save.historyPoints,
      lastActiveAt: DateTime.now(),
      processedTransactions: _save.processedTransactions,
      entitlements: _save.entitlements,
    );
    return true;
  }

  bool upgrade(int x, int y) {
    final i = _save.buildings.indexWhere((b) => b['x'] == x && b['y'] == y);
    if (i < 0) return false;
    final old = _save.buildings[i];
    final d = buildings.firstWhere((b) => b.id == old['id']);
    final level = old['level'] as int? ?? 1;
    final cost = economy.levelCost(d, level);
    if (level >= d.maxLevel || _save.coins < cost) return false;
    final updated = Map<String, dynamic>.from(old)
      ..['level'] = level + 1
      ..['income'] = economy.incomePerHour(d, level + 1)
      ..['population'] = economy.population(d, level + 1);
    final list = [..._save.buildings]..[i] = updated;
    _save = GameSave(
      coins: _save.coins - cost,
      gems: _save.gems,
      buildings: list,
      era: _save.era,
      missions: _save.missions,
      achievements: _save.achievements,
      historyPoints: _save.historyPoints,
      lastActiveAt: DateTime.now(),
      processedTransactions: _save.processedTransactions,
      entitlements: _save.entitlements,
    );
    return true;
  }

  int collectIdle(DateTime now) {
    final earned = idle.calculate(
      incomePerHour: incomePerHour,
      lastActiveAt: _save.lastActiveAt ?? now,
      now: now,
    );
    _save = GameSave(
      coins: _save.coins + earned,
      gems: _save.gems,
      buildings: _save.buildings,
      era: _save.era,
      missions: _save.missions,
      achievements: _save.achievements,
      historyPoints: _save.historyPoints,
      lastActiveAt: now,
      processedTransactions: _save.processedTransactions,
      entitlements: _save.entitlements,
    );
    return earned;
  }

  bool advanceEra() {
    final next = era.index + 1;
    if (next >= Era.values.length ||
        population < (next == 1 ? 30 : 100) ||
        _save.missions.isEmpty) {
      return false;
    }
    _save = GameSave(
      coins: _save.coins,
      gems: _save.gems,
      buildings: _save.buildings,
      era: Era.values[next].name,
      missions: _save.missions,
      achievements: [..._save.achievements, 'era_${Era.values[next].name}'],
      historyPoints: _save.historyPoints,
      lastActiveAt: _save.lastActiveAt,
      processedTransactions: _save.processedTransactions,
      entitlements: _save.entitlements,
    );
    return true;
  }

  void historyReset() {
    final result = resetForHistory(
      currentPopulation: population,
      currentHistoryPoints: _save.historyPoints,
      gems: _save.gems,
      entitlements: _save.entitlements.toSet(),
    );
    _save = GameSave(
      gems: result.gems,
      historyPoints: result.historyPoints,
      entitlements: result.entitlements.toList(),
    );
  }
}
