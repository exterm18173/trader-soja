// lib/views/fx/fx_model_runs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/fx/fx_model_runs_vm.dart';
import '../../routes/app_routes.dart';

class FxModelRunsScreen extends StatefulWidget {
  const FxModelRunsScreen({super.key});

  @override
  State<FxModelRunsScreen> createState() => _FxModelRunsScreenState();
}

class _FxModelRunsScreenState extends State<FxModelRunsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FxModelRunsVM>().load();
    });
  }

  String _fmtDt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Consumer<FxModelRunsVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FX Model Runs'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : vm.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (vm.latest != null)
                  Card(
                    child: ListTile(
                      title: Text('Latest Run #${vm.latest!.id}'),
                      subtitle: Text('as_of: ${_fmtDt(vm.latest!.asOfTs)} • source: ${vm.latest!.source}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.fxModelRunDetail,
                        arguments: vm.latest!.id,
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
                      if (vm.rows.isEmpty) {
                        return const Center(child: Text('Sem runs.'));
                      }

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = vm.rows[i];
                          return ListTile(
                            title: Text('Run #${r.id} • ${r.modelVersion} • ${r.source}'),
                            subtitle: Text(
                              'as_of: ${_fmtDt(r.asOfTs)} • spot: ${r.spotUsdbrl.toStringAsFixed(4)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.fxModelRunDetail,
                              arguments: r.id,
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
