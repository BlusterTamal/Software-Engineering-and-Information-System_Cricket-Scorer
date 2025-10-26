// lib\features\cricket_scoring\models\dismissal_model.dart

class DismissalModel {
  final String id;
  final String deliveryId;
  final String batsmanId;
  final String dismissalType;
  final String? fielder1Id;
  final String? fielder2Id;

  DismissalModel({
    required this.id,
    required this.deliveryId,
    required this.batsmanId,
    required this.dismissalType,
    this.fielder1Id,
    this.fielder2Id,
  });

  factory DismissalModel.fromMap(Map<String, dynamic> map) {
    return DismissalModel(
      id: map['\$id'] ?? '',
      deliveryId: map['deliveryId'] ?? '',
      batsmanId: map['batsmanId'] ?? '',
      dismissalType: map['dismissalType'] ?? '',
      fielder1Id: map['fielder1_Id'],
      fielder2Id: map['fielder2_Id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryId': deliveryId,
      'batsmanId': batsmanId,
      'dismissalType': dismissalType,
      'fielder1_Id': fielder1Id,
      'fielder2_Id': fielder2Id,
    };
  }

  DismissalModel copyWith({
    String? id,
    String? deliveryId,
    String? batsmanId,
    String? dismissalType,
    String? fielder1Id,
    String? fielder2Id,
  }) {
    return DismissalModel(
      id: id ?? this.id,
      deliveryId: deliveryId ?? this.deliveryId,
      batsmanId: batsmanId ?? this.batsmanId,
      dismissalType: dismissalType ?? this.dismissalType,
      fielder1Id: fielder1Id ?? this.fielder1Id,
      fielder2Id: fielder2Id ?? this.fielder2Id,
    );
  }
}