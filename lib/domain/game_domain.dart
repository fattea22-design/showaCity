enum Era { showa, heisei, reiwa }

enum BuildingCategory { residential, commercial, public, landmark }

class BuildingDefinition {
  const BuildingDefinition({
    required this.id,
    required this.era,
    required this.category,
    required this.baseCost,
    required this.baseIncome,
    required this.basePopulation,
    this.maxLevel = 10,
  });

  final String id;
  final Era era;
  final BuildingCategory category;
  final int baseCost;
  final int baseIncome;
  final int basePopulation;
  final int maxLevel;
}

class BalanceConfig {
  const BalanceConfig({
    this.levelCostGrowth = 1.18,
    this.levelIncomeGrowth = 1.15,
  });

  final double levelCostGrowth;
  final double levelIncomeGrowth;
}

class EconomyCalculator {
  const EconomyCalculator(this.balance);

  final BalanceConfig balance;

  int levelCost(BuildingDefinition building, int level) {
    _checkLevel(building, level);
    return (building.baseCost * _pow(balance.levelCostGrowth, level - 1))
        .round();
  }

  int incomePerHour(BuildingDefinition building, int level) {
    _checkLevel(building, level);
    return (building.baseIncome * _pow(balance.levelIncomeGrowth, level - 1))
        .round();
  }

  int population(BuildingDefinition building, int level) {
    _checkLevel(building, level);
    return building.basePopulation * level;
  }

  double _pow(double value, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= value;
    }
    return result;
  }

  void _checkLevel(BuildingDefinition building, int level) {
    if (level < 1 || level > building.maxLevel) {
      throw RangeError.range(level, 1, building.maxLevel, 'level');
    }
  }
}

class IdleIncomeCalculator {
  const IdleIncomeCalculator({this.maxHours = 8});

  final int maxHours;

  int calculate({
    required int incomePerHour,
    required DateTime lastActiveAt,
    required DateTime now,
  }) {
    final seconds = now.difference(lastActiveAt).inSeconds;
    if (seconds <= 0 || incomePerHour <= 0) return 0;
    final cappedSeconds = seconds.clamp(0, maxHours * 60 * 60);
    return (incomePerHour * cappedSeconds / 3600).floor();
  }
}

class EraRequirement {
  const EraRequirement({
    required this.population,
    required this.coins,
    required this.missions,
  });

  final int population;
  final int coins;
  final int missions;

  bool isMet({
    required int currentPopulation,
    required int currentCoins,
    required int completedMissions,
  }) =>
      currentPopulation >= population &&
      currentCoins >= coins &&
      completedMissions >= missions;
}

class HistoryResetResult {
  const HistoryResetResult({
    required this.historyPoints,
    required this.gems,
    required this.entitlements,
  });

  final int historyPoints;
  final int gems;
  final Set<String> entitlements;
}

HistoryResetResult resetForHistory({
  required int currentPopulation,
  required int currentHistoryPoints,
  required int gems,
  required Set<String> entitlements,
}) {
  final earnedPoints = currentPopulation ~/ 100;
  return HistoryResetResult(
    historyPoints: currentHistoryPoints + earnedPoints,
    gems: gems,
    entitlements: Set.unmodifiable(entitlements),
  );
}
