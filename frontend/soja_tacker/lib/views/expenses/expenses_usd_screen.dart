// lib/views/expenses/expenses_usd_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/expenses/expense_usd_read.dart';
import '../../viewmodels/expenses/expenses_usd_vm.dart';
import 'widgets/expense_usd_form_dialog.dart';

class ExpensesUsdScreen extends StatefulWidget {
  const ExpensesUsdScreen({super.key});

  @override
  State<ExpensesUsdScreen> createState() => _ExpensesUsdScreenState();
}

class _ExpensesUsdScreenState extends State<ExpensesUsdScreen> {
  final _catCtrl = TextEditingController();
  DateTime? _fromMes;
  DateTime? _toMes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpensesUsdVM>().load();
    });
  }

  @override
  void dispose() {
    _catCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickMes({required bool isFrom}) async {
    final initial = (isFrom ? _fromMes : _toMes) ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      final val = DateTime(d.year, d.month, 1);
      if (isFrom) {
        _fromMes = val;
      } else {
        _toMes = val;
      }
    });
  }

  void _applyFilters() {
    final vm = context.read<ExpensesUsdVM>();
    vm.setFilters(
      fromMes: _fromMes,
      toMes: _toMes,
      categoria: _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim(),
    );
    vm.load();
  }

  Future<void> _create() async {
    final res = await showDialog<ExpenseUsdFormResult>(
      context: context,
      builder: (_) => const ExpenseUsdFormDialog(),
    );
    if (!mounted || res?.create == null) return;

    final ok = await context.read<ExpensesUsdVM>().create(res!.create!);
    if (!mounted) return;

    if (!ok) {
      final msg = context.read<ExpensesUsdVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _edit(ExpenseUsdRead row) async {
    final res = await showDialog<ExpenseUsdFormResult>(
      context: context,
      builder: (_) => ExpenseUsdFormDialog(initial: row),
    );
    if (!mounted || res?.update == null) return;

    final ok = await context.read<ExpensesUsdVM>().update(row.id, res!.update!);
    if (!mounted) return;

    if (!ok) {
      final msg = context.read<ExpensesUsdVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _delete(ExpenseUsdRead row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir despesa?'),
        content: Text('Confirma excluir a despesa #${row.id} (${row.valorUsd.toStringAsFixed(2)} USD)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (!mounted || yes != true) return;

    final ok = await context.read<ExpensesUsdVM>().delete(row.id);
    if (!mounted) return;

    if (!ok) {
      final msg = context.read<ExpensesUsdVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpensesUsdVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Despesas USD'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : vm.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: vm.loading ? null : _create,
            child: const Icon(Icons.add),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // filtros
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('De (mês)'),
                                subtitle: Text(_fromMes == null ? '—' : _fmt(_fromMes!)),
                                trailing: IconButton(
                                  onPressed: () => _pickMes(isFrom: true),
                                  icon: const Icon(Icons.calendar_month),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Até (mês)'),
                                subtitle: Text(_toMes == null ? '—' : _fmt(_toMes!)),
                                trailing: IconButton(
                                  onPressed: () => _pickMes(isFrom: false),
                                  icon: const Icon(Icons.calendar_month),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _catCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Categoria (opcional)',
                            prefixIcon: Icon(Icons.filter_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: vm.loading ? null : _applyFilters,
                                icon: const Icon(Icons.search),
                                label: const Text('Aplicar filtros'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // total
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ${vm.totalUsd.toStringAsFixed(2)} USD',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (vm.loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                Expanded(
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
                      if (vm.rows.isEmpty) {
                        return const Center(child: Text('Nenhuma despesa encontrada.'));
                      }

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = vm.rows[i];
                          return ListTile(
                            title: Text('${r.valorUsd.toStringAsFixed(2)} USD • ${_fmt(r.competenciaMes)}'),
                            subtitle: Text('${r.categoria ?? 'Sem categoria'}${r.descricao != null ? ' • ${r.descricao}' : ''}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: vm.loading ? null : () => _edit(r),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Excluir',
                                  onPressed: vm.loading ? null : () => _delete(r),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
