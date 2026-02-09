// lib/views/contracts/contract_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/contracts/contract_detail_vm.dart';
import '../../data/models/contracts/contract_update.dart';
import 'widgets/contract_update_dialog.dart';

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
      final vm = context.read<ContractDetailVM>();
      vm.init(widget.contractId);
      vm.load();
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _edit() async {
    final vm = context.read<ContractDetailVM>();
    final c = vm.contract;
    if (c == null) return;

    final ContractUpdate? payload = await showDialog<ContractUpdate>(
      context: context,
      builder: (_) => ContractUpdateDialog(contract: c),
    );
    if (!mounted || payload == null) return;

    final ok = await vm.update(payload);
    if (!mounted) return;

    if (!ok) {
      final err = vm.error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContractDetailVM>(
      builder: (_, vm, __) {
        final c = vm.contract;

        return Scaffold(
          appBar: AppBar(
            title: Text('Contrato #${widget.contractId}'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : vm.load,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: (vm.loading || c == null) ? null : _edit,
                icon: const Icon(Icons.edit),
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
                          onPressed: vm.load,
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
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/hedges',
                                arguments: c.id,
                              ),
                              icon: const Icon(Icons.shield_outlined),
                              label: const Text('Ver hedges'),
                            ),

                            Text(
                              '${c.produto} • ${c.tipoPrecificacao}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _chip('Status', c.status),
                                _chip('Entrega', _fmtDate(c.dataEntrega)),
                                _chip(
                                  'Volume',
                                  '${c.volumeInputValue} ${c.volumeInputUnit}',
                                ),
                                _chip(
                                  'Total ton',
                                  c.volumeTotalTon.toStringAsFixed(2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Preço fixo: ${c.precoFixoBrlValue?.toStringAsFixed(2) ?? "-"} ${c.precoFixoBrlUnit ?? ""}',
                            ),
                            const SizedBox(height: 6),
                            Text('Observação: ${c.observacao ?? "-"}'),
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

  Widget _chip(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }
}
