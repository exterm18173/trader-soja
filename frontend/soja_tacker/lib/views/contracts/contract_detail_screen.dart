import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/contracts/contracts_vm.dart';
import '../../data/models/contracts/contract_read.dart';
import '../../data/models/contracts/contract_update.dart';
import 'widgets/contract_edit_dialog.dart';

class ContractDetailScreen extends StatefulWidget {
  final int contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContractsVM>().getOne(widget.contractId);
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _freteLine(ContractRead c) {
    final total = c.freteBrlTotal;
    final perTon = c.freteBrlPerTon;
    if (total == null && perTon == null) return '-';
    if (total != null) return 'R\$ ${total.toStringAsFixed(2)}';
    return 'R\$ ${perTon!.toStringAsFixed(2)}/ton';
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
    Navigator.pop(context); // volta pra lista
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContractsVM>(
      builder: (_, vm, __) {
        final c = vm.byId[widget.contractId];

        return Scaffold(
          appBar: AppBar(
            title: Text(c == null ? 'Contrato' : 'Contrato #${c.id}'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : () => vm.getOne(widget.contractId, force: true),
                icon: const Icon(Icons.refresh),
              ),
              if (c != null)
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
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (_) {
                if (vm.loading && c == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.error != null && c == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.error!.message),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => vm.getOne(widget.contractId, force: true),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                if (c == null) {
                  return const Center(child: Text('Contrato não encontrado.'));
                }

                return ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.produto} • ${c.tipoPrecificacao}', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text('Status: ${c.status}'),
                            Text('Entrega: ${_fmtDate(c.dataEntrega)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Volume', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Input: ${c.volumeInputValue.toStringAsFixed(2)} ${c.volumeInputUnit}'),
                            Text('Total: ${c.volumeTotalTon.toStringAsFixed(2)} ton'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preço / Frete', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Preço fixo: ${c.precoFixoBrlValue == null ? '-' : 'R\$ ${c.precoFixoBrlValue!.toStringAsFixed(2)}'}'),
                            Text('Unidade: ${c.precoFixoBrlUnit ?? '-'}'),
                            Text('Frete: ${_freteLine(c)}'),
                            if ((c.freteObs ?? '').trim().isNotEmpty) Text('Obs frete: ${c.freteObs}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Observação', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text((c.observacao ?? '').trim().isEmpty ? '-' : c.observacao!),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
