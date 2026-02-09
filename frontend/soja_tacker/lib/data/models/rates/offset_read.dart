// lib/data/models/rates/offset_read.dart
class OffsetRead {
  final int id;
  final int farmId;
  final int createdByUserId;
  final double offsetValue;
  final String? note;

  const OffsetRead({
    required this.id,
    required this.farmId,
    required this.createdByUserId,
    required this.offsetValue,
    this.note,
  });

  factory OffsetRead.fromJson(Map<String, dynamic> json) {
    return OffsetRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      offsetValue: (json['offset_value'] as num).toDouble(),
      note: (json['note'] as String?)?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farm_id': farmId,
        'created_by_user_id': createdByUserId,
        'offset_value': offsetValue,
        'note': note,
      };
}
