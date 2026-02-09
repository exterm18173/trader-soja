// lib/data/models/rates/offset_create.dart
class OffsetCreate {
  final double offsetValue;
  final String? note;

  const OffsetCreate({
    required this.offsetValue,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'offset_value': offsetValue,
        if (note != null) 'note': note,
      };
}
