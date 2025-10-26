// lib\features\cricket_scoring\models\player_match_stats_model.dart

class PlayerMatchStatsModel {
  final String id;
  final String matchId;
  final String playerId;
  final String playerName;
  final String teamId;
  final String role;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final int wickets;
  final double overs;
  final int maidens;
  final int runsConceded;
  final double economyRate;
  final double strikeRate;
  final double battingAverage;
  final double bowlingAverage;
  final bool isNotOut;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlayerMatchStatsModel({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    required this.teamId,
    required this.role,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.wickets,
    required this.overs,
    required this.maidens,
    required this.runsConceded,
    required this.economyRate,
    required this.strikeRate,
    required this.battingAverage,
    required this.bowlingAverage,
    required this.isNotOut,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerMatchStatsModel.fromMap(Map<String, dynamic> map) {
    return PlayerMatchStatsModel(
      id: map['\$id'] ?? map['id'] ?? '',
      matchId: map['matchId'] ?? '',
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      teamId: map['teamId'] ?? '',
      role: map['role'] ?? 'batsman',
      runs: map['runs'] ?? 0,
      balls: map['balls'] ?? 0,
      fours: map['fours'] ?? 0,
      sixes: map['sixes'] ?? 0,
      wickets: map['wickets'] ?? 0,
      overs: (map['overs'] ?? 0.0).toDouble(),
      maidens: map['maidens'] ?? 0,
      runsConceded: map['runsConceded'] ?? 0,
      economyRate: (map['economyRate'] ?? 0.0).toDouble(),
      strikeRate: (map['strikeRate'] ?? 0.0).toDouble(),
      battingAverage: (map['battingAverage'] ?? 0.0).toDouble(),
      bowlingAverage: (map['bowlingAverage'] ?? 0.0).toDouble(),
      isNotOut: map['isNotOut'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'playerId': playerId,
      'playerName': playerName,
      'teamId': teamId,
      'role': role,
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'wickets': wickets,
      'overs': overs,
      'maidens': maidens,
      'runsConceded': runsConceded,
      'economyRate': economyRate,
      'strikeRate': strikeRate,
      'battingAverage': battingAverage,
      'bowlingAverage': bowlingAverage,
      'isNotOut': isNotOut,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'matchId': matchId,
      'playerId': playerId,
      'playerName': playerName,
      'teamId': teamId,
      'role': role,
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'wickets': wickets,
      'overs': overs,
      'maidens': maidens,
      'runsConceded': runsConceded,
      'economyRate': economyRate,
      'strikeRate': strikeRate,
      'battingAverage': battingAverage,
      'bowlingAverage': bowlingAverage,
      'isNotOut': isNotOut,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PlayerMatchStatsModel copyWith({
    String? id,
    String? matchId,
    String? playerId,
    String? playerName,
    String? teamId,
    String? role,
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    int? wickets,
    double? overs,
    int? maidens,
    int? runsConceded,
    double? economyRate,
    double? strikeRate,
    double? battingAverage,
    double? bowlingAverage,
    bool? isNotOut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerMatchStatsModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      wickets: wickets ?? this.wickets,
      overs: overs ?? this.overs,
      maidens: maidens ?? this.maidens,
      runsConceded: runsConceded ?? this.runsConceded,
      economyRate: economyRate ?? this.economyRate,
      strikeRate: strikeRate ?? this.strikeRate,
      battingAverage: battingAverage ?? this.battingAverage,
      bowlingAverage: bowlingAverage ?? this.bowlingAverage,
      isNotOut: isNotOut ?? this.isNotOut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get battingStrikeRate => balls > 0 ? (runs / balls) * 100 : 0.0;
  double get bowlingEconomyRate => overs > 0 ? runsConceded / overs : 0.0;
}