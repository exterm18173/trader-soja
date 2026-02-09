// lib/views/alerts/alert_rules_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/alerts/alert_rule_read.dart';
import '../../viewmodels/alerts/alert_rules_vm.dart';
import 'widgets/alert_rule_form_dialog.dart';

class AlertRulesScreen extends StatefulWidget {
  const AlertRulesScreen({super.key});

  @override
  State<AlertRulesScreen> createState() => _AlertRulesScreenState();
}

class _AlertRulesScreenState extends State<AlertRulesScreen> {
  final _tipoCtrl = TextEditingController();
  final _qCtrl = TextEditingController();
  bool? _ativo; // null = todos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AlertRulesVM>().load());
  }

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _qCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final vm = context.read<AlertRulesVM>();
    vm.setFilters(
      ativo: _ativo,
      tipo: _tipoCtrl.text.trim().isEmpty ? null : _tipoCtrl.text.trim(),
      q: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
    );
    vm.load();
  }

  Future<void> _create() async {
    final res = await showDialog<AlertRuleFormResult>(
      context: context,
      builder: (_) => const AlertRuleFormDialog(),
    );
    if (!mounted || res?.create == null) return;

    final ok = await context.read<AlertRulesVM>().create(res!.create!);
    if (!mounted) return;
    if (!ok) {
      final msg = context.read<AlertRulesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _edit(AlertRuleRead row) async {
    final res = await showDialog<AlertRuleFormResult>(
      context: context,
      builder: (_) => AlertRuleFormDialog(initial: row),
    );
    if (!mounted || res?.update == null) return;

    final ok = await context.read<AlertRulesVM>().update(row.id, res!.update!);
    if (!mounted) return;
    if (!ok) {
      final msg = context.read<AlertRulesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertRulesVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Regras de alertas'),
            actions: [
              IconButton(onPressed: vm.loading ? null : vm.load, icon: const Icon(Icons.refresh)),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<bool?>(
                                initialValue: _ativo,
                                decoration: const InputDecoration(labelText: 'Ativo'),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('Todos')),
                                  DropdownMenuItem(value: true, child: Text('Ativos')),
                                  DropdownMenuItem(value: false, child: Text('Inativos')),
                                ],
                                onChanged: (v) => setState(() => _ativo = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _tipoCtrl,
                                decoration: const InputDecoration(labelText: 'Tipo (opcional)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _qCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Busca (q)',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: vm.loading ? null : _apply,
                                icon: const Icon(Icons.filter_alt_outlined),
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
                      if (vm.rows.isEmpty) return const Center(child: Text('Nenhuma regra encontrada.'));

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = vm.rows[i];
                          return ListTile(
                            title: Text(r.nome),
                            subtitle: Text('${r.tipo} • ${r.ativo ? 'Ativo' : 'Inativo'}'),
                            trailing: IconButton(
                              tooltip: 'Editar',
                              onPressed: vm.loading ? null : () => _edit(r),
                              icon: const Icon(Icons.edit_outlined),
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
