// lib/views/fx/fx_spot_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/fx/fx_spot_vm.dart';
import 'widgets/fx_spot_tick_form_dialog.dart';

class FxSpotScreen extends StatefulWidget {
  const FxSpotScreen({super.key});

  @override
  State<FxSpotScreen> createState() => _FxSpotScreenState();
}

class _FxSpotScreenState extends State<FxSpotScreen> {
  final _sourceCtrl = TextEditingController(text: 'B3');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FxSpotVM>().load(source: _sourceCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FxSpotTickFormDialog(title: 'Novo tick FX Spot'),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<FxSpotVM>().create(
          ts: result['ts'] as DateTime,
          price: result['price'] as double,
          source: result['source'] as String,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FxSpotVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  String _fmtTs(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Consumer<FxSpotVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FX Spot (USD/BRL)'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : () => vm.load(source: _sourceCtrl.text.trim()),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Novo tick',
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
                            controller: _sourceCtrl,
                            decoration: const InputDecoration(labelText: 'Filtrar por source (opcional)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: vm.loading ? null : () => vm.load(source: _sourceCtrl.text.trim()),
                          child: const Text('Aplicar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (vm.latest != null)
                  Card(
                    child: ListTile(
                      title: Text('Último: ${vm.latest!.price.toStringAsFixed(4)}'),
                      subtitle: Text('${_fmtTs(vm.latest!.ts)} • ${vm.latest!.source}'),
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
                                onPressed: () => vm.load(source: _sourceCtrl.text.trim()),
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (vm.rows.isEmpty) return const Center(child: Text('Sem ticks cadastrados.'));

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = vm.rows[i];
                          return ListTile(
                            title: Text(r.price.toStringAsFixed(4)),
                            subtitle: Text('${_fmtTs(r.ts)} • ${r.source}'),
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
