import 'package:flutter_test/flutter_test.dart';
import 'package:showa_city/domain/game_domain.dart';

void main() {
  const shop = BuildingDefinition(
    id: 'dagashiya',
    era: Era.showa,
    category: BuildingCategory.commercial,
    baseCost: 100,
    baseIncome: 60,
    basePopulation: 0,
  );

  group('EconomyCalculator', () {
    const calculator = EconomyCalculator(BalanceConfig());

    test('calculates positive, increasing values through level 10', () {
      expect(calculator.levelCost(shop, 1), 100);
      expect(
        calculator.levelCost(shop, 10),
        greaterThan(calculator.levelCost(shop, 1)),
      );
      expect(
        calculator.incomePerHour(shop, 10),
        greaterThan(calculator.incomePerHour(shop, 1)),
      );
    });

    test('rejects levels outside the configured range', () {
      expect(() => calculator.levelCost(shop, 0), throwsRangeError);
      expect(() => calculator.levelCost(shop, 11), throwsRangeError);
    });
  });

  group('IdleIncomeCalculator', () {
    const calculator = IdleIncomeCalculator();
    final start = DateTime(2026, 1, 1, 10);

    test('calculates income and caps it at eight hours', () {
      expect(
        calculator.calculate(
          incomePerHour: 100,
          lastActiveAt: start,
          now: start.add(const Duration(hours: 2)),
        ),
        200,
      );
      expect(
        calculator.calculate(
          incomePerHour: 100,
          lastActiveAt: start,
          now: start.add(const Duration(hours: 12)),
        ),
        800,
      );
    });

    test('returns zero for negative or future elapsed time', () {
      expect(
        calculator.calculate(
          incomePerHour: 100,
          lastActiveAt: start,
          now: start.subtract(const Duration(minutes: 1)),
        ),
        0,
      );
    });
  });

  test('era requirement is met only when every condition is satisfied', () {
    const requirement = EraRequirement(
      population: 100,
      coins: 500,
      missions: 3,
    );
    expect(
      requirement.isMet(
        currentPopulation: 100,
        currentCoins: 500,
        completedMissions: 3,
      ),
      isTrue,
    );
    expect(
      requirement.isMet(
        currentPopulation: 100,
        currentCoins: 499,
        completedMissions: 3,
      ),
      isFalse,
    );
  });

  test('history reset preserves gems and entitlements', () {
    final result = resetForHistory(
      currentPopulation: 250,
      currentHistoryPoints: 4,
      gems: 80,
      entitlements: {'permanent.boost'},
    );
    expect(result.historyPoints, 6);
    expect(result.gems, 80);
    expect(result.entitlements, contains('permanent.boost'));
  });
}
