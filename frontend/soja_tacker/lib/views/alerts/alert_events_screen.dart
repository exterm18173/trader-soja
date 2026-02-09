// lib/views/alerts/alert_events_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/alerts/alert_event_read.dart';
import '../../viewmodels/alerts/alert_events_vm.dart';

class AlertEventsScreen extends StatefulWidget {
  const AlertEventsScreen({super.key});

  @override
  State<AlertEventsScreen> createState() => _AlertEventsScreenState();
}

class _AlertEventsScreenState extends State<AlertEventsScreen> {
  bool? _read; // null=todos
  final _sevCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AlertEventsVM>().load());
  }

  @override
  void dispose() {
    _sevCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final vm = context.read<AlertEventsVM>();
    vm.setFilters(
      read: _read,
      severity: _sevCtrl.text.trim().isEmpty ? null : _sevCtrl.text.trim(),
    );
    vm.load();
  }

  String _fmtDt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  Future<void> _toggleRead(AlertEventRead e) async {
    final ok = await context.read<AlertEventsVM>().markRead(e.id, !e.read);
    if (!mounted) return;

    if (!ok) {
      final msg = context.read<AlertEventsVM>().error?.message ?? 'Erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  IconData _sevIcon(String sev) {
    final s = sev.toLowerCase();
    if (s.contains('high') || s.contains('crit') || s.contains('error')) return Icons.warning_amber;
    if (s.contains('med') || s.contains('warn')) return Icons.notification_important_outlined;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertEventsVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Eventos de alertas'),
            actions: [
              IconButton(onPressed: vm.loading ? null : vm.load, icon: const Icon(Icons.refresh)),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<bool?>(
                                initialValue: _read,
                                decoration: const InputDecoration(labelText: 'Lido'),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('Todos')),
                                  DropdownMenuItem(value: false, child: Text('Não lidos')),
                                  DropdownMenuItem(value: true, child: Text('Lidos')),
                                ],
                                onChanged: (v) => setState(() => _read = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _sevCtrl,
                                decoration: const InputDecoration(labelText: 'Severity (opcional)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: vm.loading ? null : _apply,
                                icon: const Icon(Icons.filter_alt_outlined),
                                label: const Text('Aplicar filtros'),
                              ),
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
                      if (vm.rows.isEmpty) return const Center(child: Text('Nenhum evento encontrado.'));

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final e = vm.rows[i];
                          return ListTile(
                            leading: Icon(_sevIcon(e.severity)),
                            title: Text(e.title),
                            subtitle: Text('${_fmtDt(e.triggeredAt)} • ${e.severity}\n${e.message}'),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: e.read ? 'Marcar como não lido' : 'Marcar como lido',
                              onPressed: vm.loading ? null : () => _toggleRead(e),
                              icon: Icon(e.read ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined),
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
