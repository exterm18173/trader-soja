// lib/views/rates/interest_rates_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/rates/interest_rates_vm.dart';
import 'widgets/interest_rate_form_dialog.dart';

class InterestRatesScreen extends StatefulWidget {
  const InterestRatesScreen({super.key});

  @override
  State<InterestRatesScreen> createState() => _InterestRatesScreenState();
}

class _InterestRatesScreenState extends State<InterestRatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InterestRatesVM>().load();
    });
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const InterestRateFormDialog(title: 'Novo juros'),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<InterestRatesVM>().create(
          rateDate: result['rateDate'] as DateTime,
          cdiAnnual: result['cdiAnnual'] as double,
          sofrAnnual: result['sofrAnnual'] as double,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<InterestRatesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _edit(int rowId, DateTime date, double cdi, double sofr) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => InterestRateFormDialog(
        title: 'Editar juros',
        initialDate: date,
        initialCdi: cdi,
        initialSofr: sofr,
      ),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<InterestRatesVM>().update(
          rowId: rowId,
          cdiAnnual: result['cdiAnnual'] as double,
          sofrAnnual: result['sofrAnnual'] as double,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<InterestRatesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Consumer<InterestRatesVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Juros (CDI/SOFR)'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : vm.load,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Novo',
                onPressed: vm.loading ? null : _create,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (_) {
                if (vm.loading && vm.rows.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.error != null && vm.rows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.error!.message),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: vm.load, child: const Text('Tentar novamente')),
                      ],
                    ),
                  );
                }
                if (vm.rows.isEmpty) return const Center(child: Text('Sem taxas cadastradas.'));

                return ListView.separated(
                  itemCount: vm.rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = vm.rows[i];
                    return ListTile(
                      title: Text('Data: ${_d(r.rateDate)}'),
                      subtitle: Text('CDI: ${r.cdiAnnual.toStringAsFixed(2)}% • SOFR: ${r.sofrAnnual.toStringAsFixed(2)}%'),
                      trailing: IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _edit(r.id, r.rateDate, r.cdiAnnual, r.sofrAnnual),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
