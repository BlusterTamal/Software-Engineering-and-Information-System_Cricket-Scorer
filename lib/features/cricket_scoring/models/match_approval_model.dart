// lib\features\cricket_scoring\models\match_approval_model.dart

class MatchApprovalModel {
  final String id;
  final String matchId;
  final String createdBy;
  final String createdByName;
  final String createdByEmail;
  final String status;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String matchName;
  final String teamAId;
  final String teamAName;
  final String teamBId;
  final String teamBName;
  final DateTime matchDateTime;
  final String venueId;
  final String venueName;
  final String venueLocation;
  final int totalOvers;
  final String matchFormat;

  final List<Map<String, String>> officials;

  final List<Map<String, String>> teamAPlayingXI;
  final List<Map<String, String>> teamBPlayingXI;

  MatchApprovalModel({
    required this.id,
    required this.matchId,
    required this.createdBy,
    required this.createdByName,
    required this.createdByEmail,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    required this.matchName,
    required this.teamAId,
    required this.teamAName,
    required this.teamBId,
    required this.teamBName,
    required this.matchDateTime,
    required this.venueId,
    required this.venueName,
    required this.venueLocation,
    required this.totalOvers,
    required this.matchFormat,
    required this.officials,
    required this.teamAPlayingXI,
    required this.teamBPlayingXI,
  });

  factory MatchApprovalModel.fromMap(Map<String, dynamic> map) {
    return MatchApprovalModel(
      id: map['id'] as String,
      matchId: map['matchId'] as String,
      createdBy: map['createdBy'] as String,
      createdByName: map['createdByName'] as String,
      createdByEmail: map['createdByEmail'] as String,
      status: map['status'] as String,
      approvedBy: map['approvedBy'] as String?,
      approvedByName: map['approvedByName'] as String?,
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt'] as String) : null,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      matchName: map['matchName'] as String,
      teamAId: map['teamAId'] as String,
      teamAName: map['teamAName'] as String,
      teamBId: map['teamBId'] as String,
      teamBName: map['teamBName'] as String,
      matchDateTime: DateTime.parse(map['matchDateTime'] as String),
      venueId: map['venueId'] as String,
      venueName: map['venueName'] as String,
      venueLocation: map['venueLocation'] as String,
      totalOvers: map['totalOvers'] as int,
      matchFormat: map['matchFormat'] as String,
      officials: List<Map<String, String>>.from(
          (map['officials'] as List).map((x) => Map<String, String>.from(x))
      ),
      teamAPlayingXI: List<Map<String, String>>.from(
          (map['teamAPlayingXI'] as List).map((x) => Map<String, String>.from(x))
      ),
      teamBPlayingXI: List<Map<String, String>>.from(
          (map['teamBPlayingXI'] as List).map((x) => Map<String, String>.from(x))
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByEmail': createdByEmail,
      'status': status,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'matchName': matchName,
      'teamAId': teamAId,
      'teamAName': teamAName,
      'teamBId': teamBId,
      'teamBName': teamBName,
      'matchDateTime': matchDateTime.toIso8601String(),
      'venueId': venueId,
      'venueName': venueName,
      'venueLocation': venueLocation,
      'totalOvers': totalOvers,
      'matchFormat': matchFormat,
      'officials': officials,
      'teamAPlayingXI': teamAPlayingXI,
      'teamBPlayingXI': teamBPlayingXI,
    };
  }

  MatchApprovalModel copyWith({
    String? id,
    String? matchId,
    String? createdBy,
    String? createdByName,
    String? createdByEmail,
    String? status,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? matchName,
    String? teamAId,
    String? teamAName,
    String? teamBId,
    String? teamBName,
    DateTime? matchDateTime,
    String? venueId,
    String? venueName,
    String? venueLocation,
    int? totalOvers,
    String? matchFormat,
    List<Map<String, String>>? officials,
    List<Map<String, String>>? teamAPlayingXI,
    List<Map<String, String>>? teamBPlayingXI,
  }) {
    return MatchApprovalModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      matchName: matchName ?? this.matchName,
      teamAId: teamAId ?? this.teamAId,
      teamAName: teamAName ?? this.teamAName,
      teamBId: teamBId ?? this.teamBId,
      teamBName: teamBName ?? this.teamBName,
      matchDateTime: matchDateTime ?? this.matchDateTime,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      venueLocation: venueLocation ?? this.venueLocation,
      totalOvers: totalOvers ?? this.totalOvers,
      matchFormat: matchFormat ?? this.matchFormat,
      officials: officials ?? this.officials,
      teamAPlayingXI: teamAPlayingXI ?? this.teamAPlayingXI,
      teamBPlayingXI: teamBPlayingXI ?? this.teamBPlayingXI,
    );
  }
}