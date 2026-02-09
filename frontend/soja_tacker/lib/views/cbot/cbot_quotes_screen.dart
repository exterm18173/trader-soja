// lib/views/cbot/cbot_quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/cbot/cbot_quote_read.dart';
import '../../viewmodels/cbot/cbot_quotes_vm.dart';

class CbotQuotesScreen extends StatefulWidget {
  const CbotQuotesScreen({super.key});

  @override
  State<CbotQuotesScreen> createState() => _CbotQuotesScreenState();
}

class _CbotQuotesScreenState extends State<CbotQuotesScreen> {
  final _symbolCtrl = TextEditingController(text: 'ZS=F');
  final _sourceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CbotQuotesVM>().load(symbol: _symbolCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  String _fmtDt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _apply() {
    final symbol = _symbolCtrl.text.trim().isEmpty ? 'ZS=F' : _symbolCtrl.text.trim();
    final sourceId = int.tryParse(_sourceCtrl.text.trim());
    context.read<CbotQuotesVM>().load(symbol: symbol, sourceId: sourceId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CbotQuotesVM>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CBOT Quotes'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: vm.loading ? null : _apply,
                icon: const Icon(Icons.refresh),
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
                                controller: _symbolCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Symbol (ex: ZS=F)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _sourceCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Source ID (opcional)',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: vm.loading ? null : _apply,
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (vm.latest != null)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${vm.latest!.symbol} • ${vm.latest!.priceUsdPerBu.toStringAsFixed(4)} USD/bu',
                      ),
                      subtitle: Text(
                        'Latest • capturado: ${_fmtDt(vm.latest!.capturadoEm)} • source_id: ${vm.latest!.sourceId}',
                      ),
                      onTap: () => _showDetails(vm.latest!),
                      trailing: const Icon(Icons.info_outline),
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
                              ElevatedButton(onPressed: _apply, child: const Text('Tentar novamente')),
                            ],
                          ),
                        );
                      }
                      if (vm.rows.isEmpty) {
                        return const Center(child: Text('Sem quotes.'));
                      }

                      return ListView.separated(
                        itemCount: vm.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final CbotQuoteRead q = vm.rows[i];
                          return ListTile(
                            title: Text('${q.symbol} • ${q.priceUsdPerBu.toStringAsFixed(4)} USD/bu'),
                            subtitle: Text('capturado: ${_fmtDt(q.capturadoEm)} • source_id: ${q.sourceId} • id: ${q.id}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showDetails(q),
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

  void _showDetails(CbotQuoteRead q) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('CBOT Quote #${q.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('farm_id: ${q.farmId}'),
            Text('source_id: ${q.sourceId}'),
            Text('symbol: ${q.symbol}'),
            const SizedBox(height: 8),
            Text('price_usd_per_bu: ${q.priceUsdPerBu.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            Text('capturado_em: ${_fmtDt(q.capturadoEm)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
