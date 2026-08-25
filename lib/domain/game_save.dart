import 'dart:convert';

class GameSave {
  const GameSave({
    this.schemaVersion = currentSchemaVersion,
    this.coins = 0,
    this.gems = 0,
    this.buildings = const <Map<String, dynamic>>[],
    this.areas = const <String>[],
    this.era = 'showa',
    this.missions = const <String>[],
    this.achievements = const <String>[],
    this.historyPoints = 0,
    this.lastActiveAt,
    this.processedTransactions = const <String>[],
    this.entitlements = const <String>[],
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int coins;
  final int gems;
  final List<Map<String, dynamic>> buildings;
  final List<String> areas;
  final String era;
  final List<String> missions;
  final List<String> achievements;
  final int historyPoints;
  final DateTime? lastActiveAt;
  final List<String> processedTransactions;
  final List<String> entitlements;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'coins': coins,
    'gems': gems,
    'buildings': buildings,
    'areas': areas,
    'era': era,
    'missions': missions,
    'achievements': achievements,
    'historyPoints': historyPoints,
    'lastActiveAt': lastActiveAt?.toIso8601String(),
    'processedTransactions': processedTransactions,
    'entitlements': entitlements,
  };

  String encode() => jsonEncode(toJson());

  factory GameSave.fromJson(Map<String, dynamic> json) => GameSave(
    schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),
    coins: _nonNegativeInt(json['coins']),
    gems: _nonNegativeInt(json['gems']),
    buildings: _maps(json['buildings']),
    areas: _strings(json['areas']),
    era: json['era'] is String ? json['era'] as String : 'showa',
    missions: _strings(json['missions']),
    achievements: _strings(json['achievements']),
    historyPoints: _nonNegativeInt(json['historyPoints']),
    lastActiveAt: _date(json['lastActiveAt']),
    processedTransactions: _strings(json['processedTransactions']),
    entitlements: _strings(json['entitlements']),
  );

  factory GameSave.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>)
      throw const FormatException('Save root must be an object');
    return migrate(decoded);
  }

  static GameSave migrate(Map<String, dynamic> json) {
    final version = _int(json['schemaVersion'], 0);
    if (version > currentSchemaVersion)
      throw const FormatException('Unsupported save version');
    final migrated = Map<String, dynamic>.from(json);
    migrated['schemaVersion'] = currentSchemaVersion;
    migrated['processedTransactions'] ??= <String>[];
    migrated['entitlements'] ??= <String>[];
    return GameSave.fromJson(migrated);
  }

  static GameSave safeDecode(String value) {
    try {
      return GameSave.decode(value);
    } catch (_) {
      return const GameSave();
    }
  }

  static int _int(Object? value, int fallback) =>
      value is int ? value : fallback;
  static int _nonNegativeInt(Object? value) =>
      value is int && value >= 0 ? value : 0;
  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : <String>[];
  static List<Map<String, dynamic>> _maps(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
