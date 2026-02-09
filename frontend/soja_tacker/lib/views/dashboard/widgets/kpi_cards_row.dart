import 'package:flutter/material.dart';
import '../../../viewmodels/dashboard/dashboard_vm.dart';

class KpiCardsRow extends StatelessWidget {
  final DashboardVM vm;
  const KpiCardsRow({super.key, required this.vm});

  Widget _kpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto você não pluga os repos reais, fica "--"
    final fxSpot = vm.fxSpotLatest;   // quando plugar: fxSpot.price
    final cbot = vm.cbotLatest;       // quando plugar: cbot.priceUsdPerBu
    final cdi = vm.interestLatest;    // quando plugar: cdi.cdiAnnual
    final off = vm.offsetLatest;      // quando plugar: off.offsetValue

    String showNum(dynamic v) {
      if (v == null) return '--';
      if (v is num) return v.toStringAsFixed(2);
      return '--';
    }

    return Column(
      children: [
        Row(
          children: [
            _kpiCard(context, title: 'USD/BRL Spot', value: showNum(fxSpot), icon: Icons.currency_exchange),
            const SizedBox(width: 12),
            _kpiCard(context, title: 'CBOT Soja', value: showNum(cbot), icon: Icons.show_chart),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _kpiCard(context, title: 'CDI a.a.', value: showNum(cdi), icon: Icons.percent),
            const SizedBox(width: 12),
            _kpiCard(context, title: 'Offset', value: showNum(off), icon: Icons.tune),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _kpiCard(
              context,
              title: 'Alertas (não lidos)',
              value: vm.unreadAlertsCount.toString(),
              icon: Icons.notifications_active,
            ),
            const SizedBox(width: 12),
            _kpiCard(
              context,
              title: 'Linhas USD (período)',
              value: (vm.exposure?.rows.length ?? 0).toString(),
              icon: Icons.table_chart,
            ),
          ],
        ),
      ],
    );
  }
}
