// lib/views/fx/fx_sources_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/fx/fx_sources_vm.dart';

class FxSourcesScreen extends StatefulWidget {
  const FxSourcesScreen({super.key});

  @override
  State<FxSourcesScreen> createState() => _FxSourcesScreenState();
}

class _FxSourcesScreenState extends State<FxSourcesScreen> {
  final _nomeCtrl = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FxSourcesVM>().load();
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.length < 2) return;

    final ok = await context.read<FxSourcesVM>().create(nome: nome, ativo: _ativo);

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FxSourcesVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    _nomeCtrl.clear();
    setState(() => _ativo = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FxSourcesVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FX Sources'),
            actions: [
              IconButton(
                tooltip: 'Somente ativos',
                icon: Icon(vm.onlyActive ? Icons.toggle_on : Icons.toggle_off),
                onPressed: vm.loading ? null : () => vm.load(onlyActive: !vm.onlyActive),
              ),
              IconButton(
                tooltip: 'Atualizar',
                icon: const Icon(Icons.refresh),
                onPressed: vm.loading ? null : vm.load,
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
                        TextField(
                          controller: _nomeCtrl,
                          decoration: const InputDecoration(labelText: 'Nome da fonte (ex: Investing, B3, Manual)'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Ativo'),
                                value: _ativo,
                                onChanged: (v) => setState(() => _ativo = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: vm.loading ? null : _create,
                              child: const Text('Criar'),
                            ),
                          ],
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
                              ElevatedButton(onPressed: vm.load, child: const Text('Tentar novamente')),
                            ],
                          ),
                        );
                      }
                      if (vm.rows.isEmpty) return const Center(child: Text('Sem fontes cadastradas.'));

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = vm.rows[i];
                          return ListTile(
                            title: Text(r.nome),
                            subtitle: Text('id: ${r.id}'),
                            trailing: Chip(label: Text(r.ativo ? 'Ativo' : 'Inativo')),
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
