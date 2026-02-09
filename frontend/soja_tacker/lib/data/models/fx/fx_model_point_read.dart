// lib/data/models/fx/fx_model_point_read.dart
class FxModelPointRead {
  final DateTime refMes; // date
  final double tAnos;
  final double dolarSint;
  final double dolarDesc;

  const FxModelPointRead({
    required this.refMes,
    required this.tAnos,
    required this.dolarSint,
    required this.dolarDesc,
  });

  factory FxModelPointRead.fromJson(Map<String, dynamic> json) {
    return FxModelPointRead(
      refMes: DateTime.parse(json['ref_mes'] as String),
      tAnos: (json['t_anos'] as num).toDouble(),
      dolarSint: (json['dolar_sint'] as num).toDouble(),
      dolarDesc: (json['dolar_desc'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ref_mes': refMes.toIso8601String().substring(0, 10),
        't_anos': tAnos,
        'dolar_sint': dolarSint,
        'dolar_desc': dolarDesc,
      };
}
