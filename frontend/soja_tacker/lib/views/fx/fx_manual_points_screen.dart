// lib/views/fx/fx_manual_points_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/fx/fx_manual_point_read.dart';
import '../../viewmodels/fx/fx_manual_points_vm.dart';
import 'widgets/fx_manual_point_form_dialog.dart';

class FxManualPointsScreen extends StatefulWidget {
  const FxManualPointsScreen({super.key});

  @override
  State<FxManualPointsScreen> createState() => _FxManualPointsScreenState();
}

class _FxManualPointsScreenState extends State<FxManualPointsScreen> {
  final _sourceCtrl = TextEditingController();
  DateTime? _refMes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FxManualPointsVM>().load();
    });
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    super.dispose();
  }

  String _fmtDt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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
    context.read<FxManualPointsVM>().load(
          sourceId: sourceId,
          refMes: _refMes,
        );
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FxManualPointFormDialog(title: 'Novo ponto manual FX'),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<FxManualPointsVM>().create(
          sourceId: result['sourceId'] as int,
          capturedAt: result['capturedAt'] as DateTime,
          refMes: result['refMes'] as DateTime,
          fx: result['fx'] as double,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FxManualPointsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _edit(FxManualPointRead r) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => FxManualPointFormDialog(
        title: 'Editar ponto manual FX',
        initialSourceId: r.sourceId,
        initialCapturedAt: r.capturedAt,
        initialRefMes: r.refMes,
        initialFx: r.fx,
      ),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<FxManualPointsVM>().update(
          pointId: r.id,
          capturedAt: result['capturedAt'] as DateTime,
          refMes: result['refMes'] as DateTime,
          fx: result['fx'] as double,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FxManualPointsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _delete(FxManualPointRead r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir ponto'),
        content: Text('Deseja excluir o ponto ${r.id} (ref: ${_fmtDate(r.refMes)})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (!mounted || yes != true) return;

    final ok = await context.read<FxManualPointsVM>().delete(r.id);

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FxManualPointsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FxManualPointsVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FX Manual Points'),
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
                                  child: Text(
                                    _refMes == null ? '—' : _fmtDate(_refMes!),
                                  ),
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
                        return const Center(child: Text('Sem pontos cadastrados.'));
                      }

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = vm.rows[i];
                          return ListTile(
                            title: Text('FX ${r.fx.toStringAsFixed(4)} • Ref ${_fmtDate(r.refMes)}'),
                            subtitle: Text('source_id: ${r.sourceId} • captured: ${_fmtDt(r.capturedAt)} • id: ${r.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => _edit(r),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  tooltip: 'Excluir',
                                  onPressed: () => _delete(r),
                                  icon: const Icon(Icons.delete),
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
