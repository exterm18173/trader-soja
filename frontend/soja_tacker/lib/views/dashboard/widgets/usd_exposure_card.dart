// lib/views/dashboard/widgets/usd_exposure_card.dart
import 'package:flutter/material.dart';

import '../../../data/models/dashboard/usd_exposure_row.dart';

class UsdExposureCard extends StatelessWidget {
  final List<UsdExposureRow> rows;
  const UsdExposureCard({super.key, required this.rows});

  String _ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final totalDesp = rows.fold<double>(0, (a, b) => a + b.despesasUsd);
    final totalRec = rows.fold<double>(0, (a, b) => a + b.receitaTravadaUsd);
    final totalSaldo = rows.fold<double>(0, (a, b) => a + b.saldoUsd);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exposição USD',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Despesas: ${totalDesp.toStringAsFixed(2)} | '
              'Receita travada: ${totalRec.toStringAsFixed(2)} | '
              'Saldo: ${totalSaldo.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Sem dados no período.'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Mês')),
                    DataColumn(label: Text('Despesas USD')),
                    DataColumn(label: Text('Receita Travada USD')),
                    DataColumn(label: Text('Saldo USD')),
                    DataColumn(label: Text('Cobertura %')),
                  ],
                  rows: rows.map((r) {
                    return DataRow(cells: [
                      DataCell(Text(_ym(r.competenciaMes))),
                      DataCell(Text(r.despesasUsd.toStringAsFixed(2))),
                      DataCell(Text(r.receitaTravadaUsd.toStringAsFixed(2))),
                      DataCell(Text(r.saldoUsd.toStringAsFixed(2))),
                      DataCell(Text(r.coberturaPct.toStringAsFixed(2))),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
