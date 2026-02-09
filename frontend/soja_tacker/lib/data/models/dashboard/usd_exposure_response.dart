// lib/data/models/dashboard/usd_exposure_response.dart
import 'usd_exposure_row.dart';

class UsdExposureResponse {
  final int farmId;
  final List<UsdExposureRow> rows;

  const UsdExposureResponse({
    required this.farmId,
    required this.rows,
  });

  factory UsdExposureResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['rows'] as List).cast<dynamic>();
    return UsdExposureResponse(
      farmId: (json['farm_id'] as num).toInt(),
      rows: list
          .map((e) => UsdExposureRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'farm_id': farmId,
        'rows': rows.map((e) => e.toJson()).toList(),
      };
}
