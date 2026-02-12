// lib/views/hedges/hedges_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/hedges/hedges_vm.dart';
import '../../data/models/hedges/hedge_cbot_create.dart';
import '../../data/models/hedges/hedge_premium_create.dart';
import '../../data/models/hedges/hedge_fx_create.dart';
import '../../data/models/contracts/contract_read.dart';

import 'widgets/hedge_cbot_form_dialog.dart';
import 'widgets/hedge_premium_form_dialog.dart';
import 'widgets/hedge_fx_form_dialog.dart';

class HedgesScreen extends StatefulWidget {
  const HedgesScreen({super.key});

  @override
  State<HedgesScreen> createState() => _HedgesScreenState();
}

class _HedgesScreenState extends State<HedgesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<HedgesVM>();
      vm.loadContracts(); // ✅ agora carrega contratos e seleciona um default
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _showErrIfNeeded(HedgesVM vm) async {
    final msg = vm.error?.message;
    if (msg == null || msg.trim().isEmpty) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmDelete(String title, String body) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _createCbot() async {
    final vm = context.read<HedgesVM>();
    if (vm.contractId == null) return;

    final HedgeCbotCreate? payload = await showDialog<HedgeCbotCreate>(
      context: context,
      builder: (_) => const HedgeCbotFormDialog(),
    );
    if (!mounted || payload == null) return;

    final ok = await vm.createCbot(payload);
    if (!mounted) return;
    if (!ok) await _showErrIfNeeded(vm);
  }

  Future<void> _createPremium() async {
    final vm = context.read<HedgesVM>();
    if (vm.contractId == null) return;

    final HedgePremiumCreate? payload = await showDialog<HedgePremiumCreate>(
      context: context,
      builder: (_) => const HedgePremiumFormDialog(),
    );
    if (!mounted || payload == null) return;

    final ok = await vm.createPremium(payload);
    if (!mounted) return;
    if (!ok) await _showErrIfNeeded(vm);
  }

  Future<void> _createFx() async {
    final vm = context.read<HedgesVM>();
    if (vm.contractId == null) return;

    final HedgeFxCreate? payload = await showDialog<HedgeFxCreate>(
      context: context,
      builder: (_) => const HedgeFxFormDialog(),
    );
    if (!mounted || payload == null) return;

    final ok = await vm.createFx(payload);
    if (!mounted) return;
    if (!ok) await _showErrIfNeeded(vm);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HedgesVM>(
      builder: (_, vm, __) {
        final hasContract = vm.selectedContract != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hedges'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading
                    ? null
                    : () async {
                        // recarrega contratos e, se selecionado, recarrega hedges
                        await vm.loadContracts();
                        if (!mounted) return;
                        await _showErrIfNeeded(vm);
                      },
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'CBOT'),
                Tab(text: 'Premium'),
                Tab(text: 'FX'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: (!hasContract || vm.loading)
                ? null
                : () {
                    final idx = _tabs.index;
                    if (idx == 0) _createCbot();
                    if (idx == 1) _createPremium();
                    if (idx == 2) _createFx();
                  },
            child: const Icon(Icons.add),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _contractPicker(vm),
                const SizedBox(height: 16),

                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (!hasContract) {
                        return const Center(
                          child: Text('Selecione um contrato para ver/criar hedges.'),
                        );
                      }

                      if (vm.loading && vm.cbot.isEmpty && vm.premium.isEmpty && vm.fx.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (vm.error != null && vm.cbot.isEmpty && vm.premium.isEmpty && vm.fx.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(vm.error!.message),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: vm.loadAll,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        );
                      }

                      return TabBarView(
                        controller: _tabs,
                        children: [
                          // CBOT
                          _list(
                            empty: 'Sem hedges CBOT.',
                            items: vm.cbot
                                .map(
                                  (h) => ListTile(
                                    title: Text(
                                      '${h.cbotUsdPerBu.toStringAsFixed(4)} USD/bu • ${h.volumeTon.toStringAsFixed(2)} ton',
                                    ),
                                    subtitle: Text(
                                      'Exec: ${_fmtDate(h.executadoEm)} • input: ${h.volumeInputValue} ${h.volumeInputUnit}'
                                      '${h.refMes != null ? ' • ref: ${_fmtDate(h.refMes!)}' : ''}'
                                      '${h.symbol != null ? ' • ${h.symbol}' : ''}',
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Excluir',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: vm.loading
                                          ? null
                                          : () async {
                                              final ok = await _confirmDelete(
                                                'Excluir hedge CBOT?',
                                                'Essa ação pode ajustar/remover hedges FX automaticamente.',
                                              );
                                              if (!ok) return;
                                              final done = await vm.deleteCbot(h.id);
                                              if (!mounted) return;
                                              if (!done) await _showErrIfNeeded(vm);
                                            },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          // Premium
                          _list(
                            empty: 'Sem hedges Premium.',
                            items: vm.premium
                                .map(
                                  (h) => ListTile(
                                    title: Text(
                                      '${h.premiumValue.toStringAsFixed(4)} ${h.premiumUnit} • ${h.volumeTon.toStringAsFixed(2)} ton',
                                    ),
                                    subtitle: Text(
                                      'Exec: ${_fmtDate(h.executadoEm)} • input: ${h.volumeInputValue} ${h.volumeInputUnit}'
                                      '${h.baseLocal != null ? ' • base: ${h.baseLocal}' : ''}',
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Excluir',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: vm.loading
                                          ? null
                                          : () async {
                                              final ok = await _confirmDelete(
                                                'Excluir hedge Premium?',
                                                'Essa ação pode ajustar/remover hedges FX automaticamente.',
                                              );
                                              if (!ok) return;
                                              final done = await vm.deletePremium(h.id);
                                              if (!mounted) return;
                                              if (!done) await _showErrIfNeeded(vm);
                                            },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          // FX
                          _list(
                            empty: 'Sem hedges FX.',
                            items: vm.fx
                                .map(
                                  (h) => ListTile(
                                    title: Text(
                                      '${h.volumeTon.toStringAsFixed(2)} ton • '
                                      '${h.usdAmount.toStringAsFixed(2)} USD @ ${h.brlPerUsd.toStringAsFixed(4)}',
                                    ),
                                    subtitle: Text(
                                      'Exec: ${_fmtDate(h.executadoEm)} • tipo: ${h.tipo}'
                                      '${h.refMes != null ? ' • ref: ${_fmtDate(h.refMes!)}' : ''}',
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Excluir',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: vm.loading
                                          ? null
                                          : () async {
                                              final ok = await _confirmDelete(
                                                'Excluir hedge FX?',
                                                'Essa ação remove apenas este hedge FX.',
                                              );
                                              if (!ok) return;
                                              final done = await vm.deleteFx(h.id);
                                              if (!mounted) return;
                                              if (!done) await _showErrIfNeeded(vm);
                                            },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
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

  Widget _contractPicker(HedgesVM vm) {
    String label(ContractRead c) {
      // monta um label bom pra bater o olho
      final entrega = _fmtDate(c.dataEntrega);
      final vol = '${c.volumeTotalTon.toStringAsFixed(2)}t';
      return '#${c.id} • ${c.produto} • $vol • $entrega • ${c.status}';
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<ContractRead>(
            value: vm.selectedContract,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Contrato',
              border: OutlineInputBorder(),
            ),
            items: vm.contracts
                .map(
                  (c) => DropdownMenuItem<ContractRead>(
                    value: c,
                    child: Text(label(c), overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: vm.loading ? null : (c) => vm.selectContract(c),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Recarregar contratos',
          onPressed: vm.loading ? null : () => vm.loadContracts(),
          icon: const Icon(Icons.sync),
        ),
      ],
    );
  }

  Widget _list({required String empty, required List<Widget> items}) {
    if (items.isEmpty) return Center(child: Text(empty));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => items[i],
    );
  }
}
