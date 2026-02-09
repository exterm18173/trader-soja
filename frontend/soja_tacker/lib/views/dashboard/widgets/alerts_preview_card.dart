import 'package:flutter/material.dart';
import '../../../viewmodels/dashboard/dashboard_vm.dart';

class AlertsPreviewCard extends StatelessWidget {
  final DashboardVM vm;
  const AlertsPreviewCard({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = vm.alertsPreview;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Alertas recentes', style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () {
                 
                    // Navigator.pushNamed(context, '/alerts');
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (items.isEmpty)
              Text('Nenhum alerta recente.', style: Theme.of(context).textTheme.bodyMedium)
            else
              ...items.take(5).map((e) {
                // Ajuste quando tiver AlertEventRead real (title/message/severity)
                final title = (e is Map && e['title'] != null) ? '${e['title']}' : 'Alerta';
                final msg = (e is Map && e['message'] != null) ? '${e['message']}' : 'Detalhes do alerta...';

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber),
                  title: Text(title),
                  subtitle: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis),
                );
              }),
          ],
        ),
      ),
    );
  }
}
