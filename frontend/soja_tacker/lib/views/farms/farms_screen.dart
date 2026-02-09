// lib/views/farms/farms_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../viewmodels/farms/farms_vm.dart';
import 'widgets/farm_form_dialog.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FarmsVM>().load();
    });
  }

  Future<void> _createFarm() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FarmFormDialog(title: 'Nova fazenda'),
    );

    if (!mounted || result == null) return;

    final ok = await context.read<FarmsVM>().createFarm(
      nome: (result['nome'] ?? '').toString(),
    );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FarmsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _editFarm({
    required int farmId,
    required String nome,
    required bool ativo,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => FarmFormDialog(
        title: 'Editar fazenda',
        initialNome: nome,
        showAtivo: true,
        initialAtivo: ativo,
      ),
    );

    if (!mounted || result == null) return;

    final ok = await context.read<FarmsVM>().updateFarm(
      farmId: farmId,
      nome: (result['nome'] ?? '').toString(),
      ativo: result['ativo'] as bool?,
    );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<FarmsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmsVM>(
      builder: (_, vm, __) {
        final selected = vm.selectedFarmId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Minhas Fazendas'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : vm.load,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Nova fazenda',
                onPressed: vm.loading ? null : _createFarm,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (_) {
                if (vm.loading && vm.memberships.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.error != null && vm.memberships.isEmpty) {
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

                if (vm.memberships.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma fazenda cadastrada.'),
                  );
                }

                return ListView.separated(
                  itemCount: vm.memberships.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = vm.memberships[i];
                    final f = m.farm;
                    final isSelected = selected == f.id;

                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.agriculture,
                      ),
                      title: Text(f.nome),
                      subtitle: Text(
                        'Role: ${m.role} • Ativo: ${f.ativo ? "Sim" : "Não"}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _editFarm(
                          farmId: f.id,
                          nome: f.nome,
                          ativo: f.ativo,
                        ),
                        icon: const Icon(Icons.edit),
                      ),
                      onTap: () async {
                        await vm.selectFarm(f.id);
                        if (!mounted) return;
                        if (context.mounted) {
                          await vm.selectFarm(f.id);
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.shell,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
