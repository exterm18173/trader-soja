// lib/data/models/expenses/expense_usd_create.dart
class ExpenseUsdCreate {
  final DateTime competenciaMes; // date
  final double valorUsd;
  final String? categoria;
  final String? descricao;

  const ExpenseUsdCreate({
    required this.competenciaMes,
    required this.valorUsd,
    this.categoria,
    this.descricao,
  });

  Map<String, dynamic> toJson() => {
        'competencia_mes': competenciaMes.toIso8601String().substring(0, 10),
        'valor_usd': valorUsd,
        'categoria': categoria,
        'descricao': descricao,
      };
}
