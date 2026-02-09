// lib/views/fx/fx_quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/fx/fx_quote_with_check_read.dart';
import '../../viewmodels/fx/fx_quotes_vm.dart';
import 'widgets/fx_quote_form_dialog.dart';

class FxQuotesScreen extends StatefulWidget {
  const FxQuotesScreen({super.key});

  @override
  State<FxQuotesScreen> createState() => _FxQuotesScreenState();
}

class _FxQuotesScreenState extends State<FxQuotesScreen> {
  final _sourceCtrl = TextEditingController();
  DateTime? _refMes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FxQuotesVM>().load();
    });
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRefMes() async {
    final now = DateTime.now();
    final initial = _refMes ?? DateTime(now.year, now.month, 1);

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    setState(() => _refMes = DateTime(d.year, d.month, 1));
  }

  void _applyFilters() {
    final sourceId = int.tryParse(_sourceCtrl.text.trim());
    context.read<FxQuotesVM>().load(
          sourceId: sourceId,
          refMes: _refMes,
        );
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FxQuoteFormDialog(title: 'Novo FX Quote'),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<FxQuotesVM>().create(
          sourceId: result['sourceId'] as int,
          capturadoEm: result['capturadoEm'] as DateTime,
          refMes: result['refMes'] as DateTime,
          brlPerUsd: result['brlPerUsd'] as double,
          observacao: result['observacao'] as String?,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FxQuotesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  String _severityLabel(double pctAbs) {
    if (pctAbs >= 5) return 'ALTO';
    if (pctAbs >= 2) return 'MÉDIO';
    return 'OK';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FxQuotesVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FX Quotes'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : _applyFilters,
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _sourceCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Filtrar Source ID (opcional)',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _pickRefMes,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Filtrar Ref Mês (opcional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(_refMes == null ? '—' : _fmtDate(_refMes!)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: vm.loading ? null : _applyFilters,
                            child: const Text('Aplicar filtros'),
                          ),
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
                              ElevatedButton(onPressed: _applyFilters, child: const Text('Tentar novamente')),
                            ],
                          ),
                        );
                      }
                      if (vm.rows.isEmpty) {
                        return const Center(child: Text('Sem quotes cadastrados.'));
                      }

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final FxQuoteWithCheckRead r = vm.rows[i];
                          final q = r.quote;
                          final c = r.check;

                          final pctAbs = c.deltaPct.abs();
                          final label = _severityLabel(pctAbs);

                          return ListTile(
                            title: Text(
                              'BRL/USD ${q.brlPerUsd.toStringAsFixed(4)} • Ref ${_fmtDate(q.refMes)}',
                            ),
                            subtitle: Text(
                              'source_id: ${q.sourceId} • Δ ${c.deltaAbs.toStringAsFixed(4)} (${c.deltaPct.toStringAsFixed(2)}%) • $label',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Check do Quote #${q.id}'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('FX Manual: ${c.fxManual.toStringAsFixed(4)}'),
                                      Text('FX Model:  ${c.fxModel.toStringAsFixed(4)}'),
                                      const SizedBox(height: 8),
                                      Text('Δ Abs: ${c.deltaAbs.toStringAsFixed(6)}'),
                                      Text('Δ %:   ${c.deltaPct.toStringAsFixed(2)}%'),
                                      const SizedBox(height: 8),
                                      Text('model_run_id: ${c.modelRunId}'),
                                      Text('model_point_id: ${c.modelPointId}'),
                                      Text('manual_point_id: ${c.manualPointId ?? '-'}'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            },
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
