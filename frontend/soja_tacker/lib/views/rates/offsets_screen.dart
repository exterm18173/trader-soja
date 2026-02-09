// lib/views/rates/offsets_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/rates/offsets_vm.dart';
import 'widgets/offset_form_dialog.dart';

class OffsetsScreen extends StatefulWidget {
  const OffsetsScreen({super.key});

  @override
  State<OffsetsScreen> createState() => _OffsetsScreenState();
}

class _OffsetsScreenState extends State<OffsetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OffsetsVM>().load();
    });
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const OffsetFormDialog(title: 'Novo offset'),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<OffsetsVM>().create(
          offsetValue: result['offsetValue'] as double,
          note: result['note'] as String?,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<OffsetsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OffsetsVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Offset'),
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
            child: Builder(
              builder: (_) {
                if (vm.loading && vm.history.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.error != null && vm.history.isEmpty) {
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

                return ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Último offset', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(vm.latest == null
                                ? 'Sem offset'
                                : 'Valor: ${vm.latest!.offsetValue.toStringAsFixed(4)}'
                                  '${vm.latest!.note != null ? " • ${vm.latest!.note}" : ""}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Histórico', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (vm.history.isEmpty)
                      const Text('Sem histórico.')
                    else
                      ...vm.history.map((r) {
                        return ListTile(
                          title: Text(r.offsetValue.toStringAsFixed(4)),
                          subtitle: Text(r.note ?? ''),
                        );
                      }),
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
