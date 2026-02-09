// lib/views/cbot/cbot_sources_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/cbot/cbot_sources_vm.dart';
import 'widgets/cbot_source_form_dialog.dart';

class CbotSourcesScreen extends StatefulWidget {
  const CbotSourcesScreen({super.key});

  @override
  State<CbotSourcesScreen> createState() => _CbotSourcesScreenState();
}

class _CbotSourcesScreenState extends State<CbotSourcesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CbotSourcesVM>().load();
    });
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CbotSourceFormDialog(title: 'Novo CBOT Source'),
    );
    if (!mounted || result == null) return;

    final ok = await context.read<CbotSourcesVM>().create(
          nome: result['nome'] as String,
          ativo: result['ativo'] as bool,
        );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<CbotSourcesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CbotSourcesVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CBOT Sources'),
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
                  child: SwitchListTile(
                    value: vm.onlyActive,
                    onChanged: vm.loading ? null : (v) => vm.load(onlyActive: v),
                    title: const Text('Mostrar somente ativos'),
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
                              ElevatedButton(onPressed: vm.load, child: const Text('Tentar novamente')),
                            ],
                          ),
                        );
                      }
                      if (vm.rows.isEmpty) {
                        return const Center(child: Text('Sem sources.'));
                      }

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = vm.rows[i];
                          return ListTile(
                            title: Text(s.nome),
                            subtitle: Text('id: ${s.id} • ativo: ${s.ativo ? "sim" : "não"}'),
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
