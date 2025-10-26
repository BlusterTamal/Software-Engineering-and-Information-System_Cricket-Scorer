// lib\features\cricket_scoring\models\tournament_model.dart

import 'package:appwrite/appwrite.dart';
import 'tournament_group_model.dart';
import 'tournament_stage_model.dart';

class TournamentModel {
  final String id;
  final String tournamentName;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String format;
  final TournamentRules rules;
  final List<TournamentGroupModel> groups;
  final List<TournamentStageModel> stages;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentModel({
    required this.id,
    required this.tournamentName,
    required this.description,
    required this.startDate,
    this.endDate,
    this.status = 'upcoming',
    required this.format,
    required this.rules,
    this.groups = const [],
    this.stages = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentModel.fromMap(Map<String, dynamic> map) {
    return TournamentModel(
      id: map['\$id'] as String,
      tournamentName: map['tournamentName'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      status: map['status'] as String,
      format: map['format'] as String,
      rules: TournamentRules.fromMap(map['rules'] as Map<String, dynamic>),
      groups: (map['groups'] as List<dynamic>?)?.map((e) => TournamentGroupModel.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      stages: (map['stages'] as List<dynamic>?)?.map((e) => TournamentStageModel.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '\$id': id,
      'tournamentName': tournamentName,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'format': format,
      'rules': rules.toMap(),
      'groups': groups.map((e) => e.toMap()).toList(),
      'stages': stages.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TournamentModel copyWith({
    String? id,
    String? tournamentName,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? format,
    TournamentRules? rules,
    List<TournamentGroupModel>? groups,
    List<TournamentStageModel>? stages,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      tournamentName: tournamentName ?? this.tournamentName,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      format: format ?? this.format,
      rules: rules ?? this.rules,
      groups: groups ?? this.groups,
      stages: stages ?? this.stages,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TournamentRules {
  final int pointsForWin;
  final int pointsForLoss;
  final int pointsForTie;
  final int pointsForNoResult;
  final int maxQualifiedFromGroup;
  final int maxQualifiedFromStage;

  const TournamentRules({
    this.pointsForWin = 2,
    this.pointsForLoss = 0,
    this.pointsForTie = 1,
    this.pointsForNoResult = 1,
    this.maxQualifiedFromGroup = 2,
    this.maxQualifiedFromStage = 2,
  });

  factory TournamentRules.fromMap(Map<String, dynamic> map) {
    return TournamentRules(
      pointsForWin: map['pointsForWin'] as int? ?? 2,
      pointsForLoss: map['pointsForLoss'] as int? ?? 0,
      pointsForTie: map['pointsForTie'] as int? ?? 1,
      pointsForNoResult: map['pointsForNoResult'] as int? ?? 1,
      maxQualifiedFromGroup: map['maxQualifiedFromGroup'] as int? ?? 2,
      maxQualifiedFromStage: map['maxQualifiedFromStage'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pointsForWin': pointsForWin,
      'pointsForLoss': pointsForLoss,
      'pointsForTie': pointsForTie,
      'pointsForNoResult': pointsForNoResult,
      'maxQualifiedFromGroup': maxQualifiedFromGroup,
      'maxQualifiedFromStage': maxQualifiedFromStage,
    };
  }

  TournamentRules copyWith({
    int? pointsForWin,
    int? pointsForLoss,
    int? pointsForTie,
    int? pointsForNoResult,
    int? maxQualifiedFromGroup,
    int? maxQualifiedFromStage,
  }) {
    return TournamentRules(
      pointsForWin: pointsForWin ?? this.pointsForWin,
      pointsForLoss: pointsForLoss ?? this.pointsForLoss,
      pointsForTie: pointsForTie ?? this.pointsForTie,
      pointsForNoResult: pointsForNoResult ?? this.pointsForNoResult,
      maxQualifiedFromGroup: maxQualifiedFromGroup ?? this.maxQualifiedFromGroup,
      maxQualifiedFromStage: maxQualifiedFromStage ?? this.maxQualifiedFromStage,
    );
  }
}