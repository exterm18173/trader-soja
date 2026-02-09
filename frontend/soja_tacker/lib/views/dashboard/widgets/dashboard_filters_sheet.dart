import 'package:flutter/material.dart';
import '../../../viewmodels/dashboard/dashboard_vm.dart';

void showDashboardFiltersSheet(BuildContext context, DashboardVM vm) {
  final now = DateTime.now();

  DateTime from = vm.fromMes ?? DateTime(now.year, now.month - 11, 1);
  DateTime to = vm.toMes ?? DateTime(now.year, now.month, 1);

  Future<DateTime?> pickMonth(DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return null;
    return DateTime(picked.year, picked.month, 1);
  }

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: () {
                    final n = DateTime.now();
                    final newTo = DateTime(n.year, n.month, 1);
                    final newFrom = DateTime(n.year, n.month - 11, 1);
                    vm.setRange(from: newFrom, to: newTo);
                    Navigator.pop(context);
                  },
                  child: const Text('12 meses'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListTile(
              title: const Text('De'),
              subtitle: Text('${from.month.toString().padLeft(2, '0')}/${from.year}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final m = await pickMonth(from);
                if (m != null) from = m;
              },
            ),
            ListTile(
              title: const Text('Até'),
              subtitle: Text('${to.month.toString().padLeft(2, '0')}/${to.year}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final m = await pickMonth(to);
                if (m != null) to = m;
              },
            ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  vm.setRange(from: from, to: to);
                  Navigator.pop(context);
                },
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
