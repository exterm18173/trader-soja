import 'package:flutter/material.dart';
import '../../../viewmodels/dashboard/dashboard_vm.dart';

class UsdExposureChartCard extends StatelessWidget {
  final DashboardVM vm;
  const UsdExposureChartCard({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final rows = vm.exposure?.rows ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Exposição USD (mensal)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (vm.loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (rows.isEmpty)
              Text(
                'Sem dados no período selecionado.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Container(
                height: 230,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  '📈 Inserir fl_chart aqui\n'
                  'Despesas / Receita Travada / Saldo + Cobertura %\n'
                  '(${rows.length} meses)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
