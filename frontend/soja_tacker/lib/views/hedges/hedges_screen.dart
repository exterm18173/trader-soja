// lib/views/hedges/hedges_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/hedges/hedges_vm.dart';
import '../../data/models/hedges/hedge_cbot_create.dart';
import '../../data/models/hedges/hedge_premium_create.dart';
import '../../data/models/hedges/hedge_fx_create.dart';
import 'widgets/hedge_cbot_form_dialog.dart';
import 'widgets/hedge_premium_form_dialog.dart';
import 'widgets/hedge_fx_form_dialog.dart';

class HedgesScreen extends StatefulWidget {
  final int contractId;
  const HedgesScreen({super.key, required this.contractId});

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
      vm.init(widget.contractId);
      vm.loadAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _createCbot() async {
    final HedgeCbotCreate? payload = await showDialog<HedgeCbotCreate>(
      context: context,
      builder: (_) => const HedgeCbotFormDialog(),
    );
    if (!mounted || payload == null) return;

    final ok = await context.read<HedgesVM>().createCbot(payload);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<HedgesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _createPremium() async {
    final HedgePremiumCreate? payload = await showDialog<HedgePremiumCreate>(
      context: context,
      builder: (_) => const HedgePremiumFormDialog(),
    );
    if (!mounted || payload == null) return;

    final ok = await context.read<HedgesVM>().createPremium(payload);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<HedgesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _createFx() async {
    final HedgeFxCreate? payload = await showDialog<HedgeFxCreate>(
      context: context,
      builder: (_) => const HedgeFxFormDialog(),
    );
    if (!mounted || payload == null) return;

    final ok = await context.read<HedgesVM>().createFx(payload);
    if (!mounted) return;

    if (!ok) {
      final err = context.read<HedgesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HedgesVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Hedges • contrato #${widget.contractId}'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : vm.loadAll,
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
            onPressed: vm.loading
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
            child: Builder(
              builder: (_) {
                if (vm.loading &&
                    vm.cbot.isEmpty &&
                    vm.premium.isEmpty &&
                    vm.fx.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.error != null &&
                    vm.cbot.isEmpty &&
                    vm.premium.isEmpty &&
                    vm.fx.isEmpty) {
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
                            ),
                          )
                          .toList(),
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

  Widget _list({required String empty, required List<Widget> items}) {
    if (items.isEmpty) return Center(child: Text(empty));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => items[i],
    );
  }
}
