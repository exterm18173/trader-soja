import 'package:flutter/material.dart';
import '../../../viewmodels/dashboard/dashboard_vm.dart';
import 'dashboard_filters_sheet.dart';

class DashboardHeader extends StatelessWidget {
  final DashboardVM vm;
  const DashboardHeader({super.key, required this.vm});

  String _fmtMes(DateTime? d) {
    if (d == null) return '--/----';
    return '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Período: ${_fmtMes(vm.fromMes)} → ${_fmtMes(vm.toMes)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Filtrar período',
          onPressed: () => showDashboardFiltersSheet(context, vm),
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }
}
