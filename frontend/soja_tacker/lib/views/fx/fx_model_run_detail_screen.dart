// lib/views/fx/fx_model_run_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/fx/fx_model_run_detail_vm.dart';

class FxModelRunDetailScreen extends StatefulWidget {
  final int runId;
  const FxModelRunDetailScreen({super.key, required this.runId});

  @override
  State<FxModelRunDetailScreen> createState() => _FxModelRunDetailScreenState();
}

class _FxModelRunDetailScreenState extends State<FxModelRunDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<FxModelRunDetailVM>();
      vm.init(widget.runId);
      vm.load(includePoints: true);
    });
  }

  String _fmtDt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Consumer<FxModelRunDetailVM>(
      builder: (_, vm, __) {
        final data = vm.data;
        final run = data?.run;
        final points = data?.points ?? const [];

        return Scaffold(
          appBar: AppBar(
            title: Text('Run #${widget.runId}'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : () => vm.load(includePoints: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (_) {
                if (vm.loading && data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.error != null && data == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.error!.message),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => vm.load(includePoints: true),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                if (data == null || run == null) {
                  return const Center(child: Text('Sem dados do run.'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'As of: ${_fmtDt(run.asOfTs)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _chip('Spot', run.spotUsdbrl.toStringAsFixed(4)),
                                _chip('CDI', '${run.cdiAnnual.toStringAsFixed(2)}%'),
                                _chip('SOFR', '${run.sofrAnnual.toStringAsFixed(2)}%'),
                                _chip('Offset', run.offsetValue.toStringAsFixed(4)),
                                _chip('Coupon', '${run.couponAnnual.toStringAsFixed(2)}%'),
                                _chip('Desc%', run.descontoPct.toStringAsFixed(2)),
                                _chip('Version', run.modelVersion),
                                _chip('Source', run.source),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Points (${points.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: points.isEmpty
                          ? const Center(child: Text('Sem points neste run.'))
                          : ListView.separated(
                              itemCount: points.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final p = points[i];
                                return ListTile(
                                  title: Text('Ref: ${_fmtDate(p.refMes)} • T=${p.tAnos.toStringAsFixed(3)} anos'),
                                  subtitle: Text(
                                    'sint: ${p.dolarSint.toStringAsFixed(4)} • desc: ${p.dolarDesc.toStringAsFixed(4)}',
                                  ),
                                );
                              },
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
    return Chip(
      label: Text('$label: $value'),
    );
  }
}
