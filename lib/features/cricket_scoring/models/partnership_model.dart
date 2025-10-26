// lib\features\cricket_scoring\models\partnership_model.dart

class PartnershipModel {
  final String id;
  final String inningsId;
  final String batsman1Id;
  final String batsman2Id;
  final int runs;
  final int balls;
  final bool isNotOut;

  PartnershipModel({
    required this.id,
    required this.inningsId,
    required this.batsman1Id,
    required this.batsman2Id,
    required this.runs,
    required this.balls,
    required this.isNotOut,
  });

  factory PartnershipModel.fromMap(Map<String, dynamic> map) {
    return PartnershipModel(
      id: map['\$id'] ?? '',
      inningsId: map['inningsId'] ?? '',
      batsman1Id: map['batsman1_Id'] ?? '',
      batsman2Id: map['batsman2_Id'] ?? '',
      runs: map['runs'] ?? 0,
      balls: map['balls'] ?? 0,
      isNotOut: map['isNotOut'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inningsId': inningsId,
      'batsman1_Id': batsman1Id,
      'batsman2_Id': batsman2Id,
      'runs': runs,
      'balls': balls,
      'isNotOut': isNotOut,
    };
  }

  PartnershipModel copyWith({
    String? id,
    String? inningsId,
    String? batsman1Id,
    String? batsman2Id,
    int? runs,
    int? balls,
    bool? isNotOut,
  }) {
    return PartnershipModel(
      id: id ?? this.id,
      inningsId: inningsId ?? this.inningsId,
      batsman1Id: batsman1Id ?? this.batsman1Id,
      batsman2Id: batsman2Id ?? this.batsman2Id,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      isNotOut: isNotOut ?? this.isNotOut,
    );
  }
}
