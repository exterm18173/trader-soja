// lib/data/models/fx/fx_model_run_with_points_read.dart
import 'fx_model_point_read.dart';
import 'fx_model_run_read.dart';

class FxModelRunWithPointsRead {
  final FxModelRunRead run;
  final List<FxModelPointRead> points;

  const FxModelRunWithPointsRead({
    required this.run,
    required this.points,
  });

  factory FxModelRunWithPointsRead.fromJson(Map<String, dynamic> json) {
    final pointsJson = (json['points'] as List?) ?? const [];
    return FxModelRunWithPointsRead(
      run: FxModelRunRead.fromJson(json),
      points: pointsJson
          .map((e) => FxModelPointRead.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
