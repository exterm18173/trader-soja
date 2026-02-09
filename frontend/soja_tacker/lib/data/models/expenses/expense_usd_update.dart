// lib/data/models/expenses/expense_usd_update.dart
class ExpenseUsdUpdate {
  final DateTime? competenciaMes; // date
  final double? valorUsd;
  final String? categoria;
  final String? descricao;

  const ExpenseUsdUpdate({
    this.competenciaMes,
    this.valorUsd,
    this.categoria,
    this.descricao,
  });

  Map<String, dynamic> toJson() => {
        if (competenciaMes != null)
          'competencia_mes': competenciaMes!.toIso8601String().substring(0, 10),
        if (valorUsd != null) 'valor_usd': valorUsd,
        if (categoria != null) 'categoria': categoria,
        if (descricao != null) 'descricao': descricao,
      };
}
