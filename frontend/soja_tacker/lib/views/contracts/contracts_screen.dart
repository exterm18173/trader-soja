// lib/views/contracts/contracts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/contracts/contract_read.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/contracts/contracts_vm.dart';
import '../../data/models/contracts/contract_create.dart';
import '../../data/models/contracts/contract_update.dart';
import 'widgets/contract_form_dialog.dart';
import 'widgets/contract_edit_dialog.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  final _qCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContractsVM>().load();
    });
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  String _freteLine(ContractRead c) {
    final total = c.freteBrlTotal;
    final perTon = c.freteBrlPerTon;

    if (total == null && perTon == null) return '';
    if (total != null) return ' • Frete: R\$ ${total.toStringAsFixed(2)}';
    return ' • Frete: R\$ ${perTon!.toStringAsFixed(2)}/ton';
  }

  Future<void> _create() async {
    final ContractCreate? payload = await showDialog<ContractCreate>(
      context: context,
      builder: (_) => const ContractFormDialog(title: 'Novo contrato'),
    );
    if (!mounted || payload == null) return;

    final ok = await context.read<ContractsVM>().create(payload);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<ContractsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _edit(ContractRead c) async {
    final ContractUpdate? payload = await showDialog<ContractUpdate>(
      context: context,
      builder: (_) => ContractEditDialog(title: 'Editar contrato', initial: c),
    );
    if (!mounted || payload == null) return;

    final ok = await context.read<ContractsVM>().update(c.id, payload);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<ContractsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atualizado!')));
  }

  Future<void> _delete(ContractRead c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir contrato'),
        content: Text('Tem certeza que deseja excluir o contrato #${c.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    final ok = await context.read<ContractsVM>().delete(c.id);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<ContractsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído!')));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Consumer<ContractsVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Contratos'),
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
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Busca (q)',
                              hintText: 'ex: observação',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: vm.loading
                              ? null
                              : () {
                                  vm.q = _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim();
                                  vm.load();
                                },
                          child: const Text('Buscar'),
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
                              ElevatedButton(
                                onPressed: vm.load,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (vm.rows.isEmpty) {
                        return const Center(child: Text('Sem contratos.'));
                      }

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = vm.rows[i];
                          return ListTile(
                            title: Text('${c.produto} • ${c.tipoPrecificacao} • ${c.status}'),
                            subtitle: Text(
                              'Entrega: ${_fmtDate(c.dataEntrega)} • '
                              'Vol: ${c.volumeInputValue.toStringAsFixed(2)} ${c.volumeInputUnit} • '
                              '${c.volumeTotalTon.toStringAsFixed(2)} ton'
                              '${_freteLine(c)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(c);
                                    if (v == 'del') _delete(c);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                                    PopupMenuItem(value: 'del', child: Text('Excluir')),
                                  ],
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.contractDetail,
                              arguments: c.id,
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
