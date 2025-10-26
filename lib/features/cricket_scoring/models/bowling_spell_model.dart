// lib\features\cricket_scoring\models\bowling_spell_model.dart

class BowlingSpellModel {
  final String id;
  final String inningsId;
  final String bowlerId;
  final int spellNumber;
  final double overs;
  final int maidens;
  final int runsConceded;
  final int wickets;

  BowlingSpellModel({
    required this.id,
    required this.inningsId,
    required this.bowlerId,
    required this.spellNumber,
    required this.overs,
    required this.maidens,
    required this.runsConceded,
    required this.wickets,
  });

  factory BowlingSpellModel.fromMap(Map<String, dynamic> map) {
    return BowlingSpellModel(
      id: map['\$id'] ?? '',
      inningsId: map['inningsId'] ?? '',
      bowlerId: map['bowlerId'] ?? '',
      spellNumber: map['spellNumber'] ?? 1,
      overs: (map['overs'] ?? 0.0).toDouble(),
      maidens: map['maidens'] ?? 0,
      runsConceded: map['runsConceded'] ?? 0,
      wickets: map['wickets'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inningsId': inningsId,
      'bowlerId': bowlerId,
      'spellNumber': spellNumber,
      'overs': overs,
      'maidens': maidens,
      'runsConceded': runsConceded,
      'wickets': wickets,
    };
  }

  BowlingSpellModel copyWith({
    String? id,
    String? inningsId,
    String? bowlerId,
    int? spellNumber,
    double? overs,
    int? maidens,
    int? runsConceded,
    int? wickets,
  }) {
    return BowlingSpellModel(
      id: id ?? this.id,
      inningsId: inningsId ?? this.inningsId,
      bowlerId: bowlerId ?? this.bowlerId,
      spellNumber: spellNumber ?? this.spellNumber,
      overs: overs ?? this.overs,
      maidens: maidens ?? this.maidens,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
    );
  }
}
