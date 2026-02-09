// lib/data/models/dashboard/usd_exposure_row.dart
class UsdExposureRow {
  final DateTime competenciaMes;
  final double despesasUsd;
  final double receitaTravadaUsd;
  final double saldoUsd;
  final double coberturaPct;

  const UsdExposureRow({
    required this.competenciaMes,
    required this.despesasUsd,
    required this.receitaTravadaUsd,
    required this.saldoUsd,
    required this.coberturaPct,
  });

  factory UsdExposureRow.fromJson(Map<String, dynamic> json) {
    return UsdExposureRow(
      competenciaMes: DateTime.parse(json['competencia_mes'] as String),
      despesasUsd: (json['despesas_usd'] as num).toDouble(),
      receitaTravadaUsd: (json['receita_travada_usd'] as num).toDouble(),
      saldoUsd: (json['saldo_usd'] as num).toDouble(),
      coberturaPct: (json['cobertura_pct'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'competencia_mes': competenciaMes.toIso8601String().substring(0, 10),
        'despesas_usd': despesasUsd,
        'receita_travada_usd': receitaTravadaUsd,
        'saldo_usd': saldoUsd,
        'cobertura_pct': coberturaPct,
      };
}
