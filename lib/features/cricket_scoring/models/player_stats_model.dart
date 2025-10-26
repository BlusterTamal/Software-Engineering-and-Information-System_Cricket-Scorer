// lib\features\cricket_scoring\models\player_stats_model.dart

class PlayerStatsModel {
  final String id;
  final String playerId;
  final String format;
  final int matches;
  final int runs;
  final int wickets;
  final double battingAverage;
  final double bowlingAverage;
  final double strikeRate;
  final double economyRate;

  PlayerStatsModel({
    required this.id,
    required this.playerId,
    required this.format,
    required this.matches,
    required this.runs,
    required this.wickets,
    required this.battingAverage,
    required this.bowlingAverage,
    required this.strikeRate,
    required this.economyRate,
  });

  factory PlayerStatsModel.fromMap(Map<String, dynamic> map) {
    return PlayerStatsModel(
      id: map['\$id'] ?? '',
      playerId: map['playerid'] ?? '',
      format: map['format'] ?? '',
      matches: map['matches'] ?? 0,
      runs: map['runs'] ?? 0,
      wickets: map['wickets'] ?? 0,
      battingAverage: (map['battingAverage'] ?? 0.0).toDouble(),
      bowlingAverage: (map['bowlingAverage'] ?? 0.0).toDouble(),
      strikeRate: (map['strikeRate'] ?? 0.0).toDouble(),
      economyRate: (map['economyRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerid': playerId,
      'format': format,
      'matches': matches,
      'runs': runs,
      'wickets': wickets,
      'battingAverage': battingAverage,
      'bowlingAverage': bowlingAverage,
      'strikeRate': strikeRate,
      'economyRate': economyRate,
    };
  }

  PlayerStatsModel copyWith({
    String? id,
    String? playerId,
    String? format,
    int? matches,
    int? runs,
    int? wickets,
    double? battingAverage,
    double? bowlingAverage,
    double? strikeRate,
    double? economyRate,
  }) {
    return PlayerStatsModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      format: format ?? this.format,
      matches: matches ?? this.matches,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      battingAverage: battingAverage ?? this.battingAverage,
      bowlingAverage: bowlingAverage ?? this.bowlingAverage,
      strikeRate: strikeRate ?? this.strikeRate,
      economyRate: economyRate ?? this.economyRate,
    );
  }
}
