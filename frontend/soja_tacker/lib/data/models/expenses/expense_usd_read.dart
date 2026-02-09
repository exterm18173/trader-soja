// lib/data/models/expenses/expense_usd_read.dart
class ExpenseUsdRead {
  final int id;
  final int farmId;
  final int createdByUserId;

  final DateTime competenciaMes; // date
  final double valorUsd;
  final String? categoria;
  final String? descricao;

  const ExpenseUsdRead({
    required this.id,
    required this.farmId,
    required this.createdByUserId,
    required this.competenciaMes,
    required this.valorUsd,
    required this.categoria,
    required this.descricao,
  });

  factory ExpenseUsdRead.fromJson(Map<String, dynamic> json) {
    return ExpenseUsdRead(
      id: (json['id'] as num).toInt(),
      farmId: (json['farm_id'] as num).toInt(),
      createdByUserId: (json['created_by_user_id'] as num).toInt(),
      competenciaMes: DateTime.parse(json['competencia_mes'] as String),
      valorUsd: (json['valor_usd'] as num).toDouble(),
      categoria: json['categoria'] as String?,
      descricao: json['descricao'] as String?,
    );
  }
}
