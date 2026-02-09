import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/fx/fx_quote_with_check_read.dart';
import '../../viewmodels/fx/fx_futures_quotes_vm.dart';
import '../../widgets/common/empty_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/loading_widget.dart';

class FxFuturesQuotesScreen extends StatelessWidget {
  final int farmId;

  const FxFuturesQuotesScreen({super.key, required this.farmId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final vm = ctx.read<FxFuturesQuotesVM>();
        vm.init(farmId: farmId);
        // load inicial fora do build “real”
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.loadInitial();
        });
        return vm;
      },
      child: const _FxFuturesQuotesBody(),
    );
  }
}

class _FxFuturesQuotesBody extends StatefulWidget {
  const _FxFuturesQuotesBody();

  @override
  State<_FxFuturesQuotesBody> createState() => _FxFuturesQuotesBodyState();
}

class _FxFuturesQuotesBodyState extends State<_FxFuturesQuotesBody> {
  final _valueCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  @override
  void dispose() {
    _valueCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  String _errMsg(Object? e) {
    if (e is ApiException) return e.message;
    return e?.toString() ?? 'Erro desconhecido';
  }

  double? _parseBrl(String s) {
    final t = s.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(t);
  }

  Future<void> _submit(FxFuturesQuotesVM vm) async {
    final v = _parseBrl(_valueCtrl.text);
    if (v == null || v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um BRL/USD válido.')),
      );
      return;
    }

    try {
      await vm.createQuote(brlPerUsd: v, observacao: _obsCtrl.text);
      _valueCtrl.clear();
      _obsCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotação lançada com sucesso!')),
      );
    } catch (_) {
      // o vm já setou error
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errMsg(vm.error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FxFuturesQuotesVM>(
      builder: (_, vm, __) {
        if (vm.loading && vm.sources.isEmpty && vm.quotes.isEmpty) {
          return const Scaffold(
            body: LoadingWidget(message: 'Carregando cotações...'),
          );
        }

        if (vm.error != null && vm.sources.isEmpty) {
          return Scaffold(
            body: ErrorRetryWidget(
              title: 'Erro ao carregar',
              message: _errMsg(vm.error),
              onRetry: () => vm.loadInitial(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cotações Futuras (BRL/USD)'),
            actions: [
              IconButton(
                tooltip: 'Recarregar',
                onPressed: () => vm.loadQuotesForSelected(),
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _FiltersRow(vm: vm),
                const SizedBox(height: 12),

                _CreateCard(
                  valueCtrl: _valueCtrl,
                  obsCtrl: _obsCtrl,
                  onSubmit: () => _submit(vm),
                  disabled: vm.loading,
                ),

                const SizedBox(height: 12),

                _SummaryRow(vm: vm),

                const SizedBox(height: 12),

                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 6, child: _ChartCard(quotes: vm.quotes)),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: _ListCard(vm: vm, errMsg: _errMsg),
                      ),
                    ],
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

// ---------------- Filters ----------------

class _FiltersRow extends StatelessWidget {
  final FxFuturesQuotesVM vm;
  const _FiltersRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final months = _nextMonths(count: 18); // meses futuros

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: vm.selectedSourceId,
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Todas as fontes'),
              ),
              ...vm.sources.map(
                (s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text('${s.nome} (#${s.id})'),
                ),
              ),
            ],
            onChanged: vm.loading
                ? null
                : (v) {
                    vm.setSource(v);
                    vm.loadQuotesForSelected();
                  },
            decoration: const InputDecoration(
              labelText: 'Fonte',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<DateTime>(
            value: vm.selectedRefMes,
            items: months
                .map(
                  (m) => DropdownMenuItem<DateTime>(
                    value: m,
                    child: Text(_fmtMonthLabel(m)),
                  ),
                )
                .toList(),
            onChanged: vm.loading ? null : (m) => vm.setRefMes(m!),
            decoration: const InputDecoration(
              labelText: 'Mês de referência (ref_mes)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Create Card ----------------

class _CreateCard extends StatelessWidget {
  final TextEditingController valueCtrl;
  final TextEditingController obsCtrl;
  final VoidCallback onSubmit;
  final bool disabled;

  const _CreateCard({
    required this.valueCtrl,
    required this.obsCtrl,
    required this.onSubmit,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lançar cotação',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: valueCtrl,
                    enabled: !disabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'BRL por USD (ex: 5,32)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: obsCtrl,
                    enabled: !disabled,
                    decoration: const InputDecoration(
                      labelText: 'Observação (opcional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: disabled ? null : onSubmit,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Summary ----------------

class _SummaryRow extends StatelessWidget {
  final FxFuturesQuotesVM vm;
  const _SummaryRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(title: 'Último Real', value: _fmtN(vm.lastReal)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'Último Modelo', value: _fmtN(vm.lastModel)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'Último Manual', value: _fmtN(vm.lastManual)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'MAPE (médio)', value: _fmtPct(vm.mapePct)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'MAE (BRL)', value: _fmtN(vm.maeAbs)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'Max erro %', value: _fmtPct(vm.maxErrPct)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

// ---------------- Chart ----------------

class _ChartCard extends StatelessWidget {
  final List<FxQuoteWithCheckRead> quotes;
  const _ChartCard({required this.quotes});

  @override
  Widget build(BuildContext context) {
    if (quotes.isEmpty) {
      return const Card(
        child: EmptyStateWidget(
          title: 'Sem dados para este mês',
          message: 'Lance uma ou mais cotações para ver o gráfico de evolução.',
          icon: Icons.show_chart,
        ),
      );
    }

    final realSpots = <FlSpot>[];
    final modelSpots = <FlSpot>[];
    final manualSpots = <FlSpot>[];

    // eixo X = índice do ponto (ordem temporal). Tooltip mostra data.
    for (var i = 0; i < quotes.length; i++) {
      final q = quotes[i];
      realSpots.add(FlSpot(i.toDouble(), q.quote.brlPerUsd));
      modelSpots.add(FlSpot(i.toDouble(), q.check.fxModel));
      manualSpots.add(FlSpot(i.toDouble(), q.check.fxManual));
    }

    final minY = _min3(realSpots, modelSpots, manualSpots);
    final maxY = _max3(realSpots, modelSpots, manualSpots);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução por lançamentos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minY == null ? null : (minY - 0.02),
                  maxY: maxY == null ? null : (maxY + 0.02),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: quotes.length <= 10
                            ? 1
                            : (quotes.length / 6).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= quotes.length)
                            return const SizedBox.shrink();
                          final dt = quotes[idx].quote.capturadoEm.toLocal();
                          final label =
                              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: realSpots,
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: modelSpots,
                      isCurved: true,
                      barWidth: 2.0,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: manualSpots,
                      isCurved: true,
                      barWidth: 2.0,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        if (touchedSpots.isEmpty) return [];
                        final idx = touchedSpots.first.x.toInt();
                        if (idx < 0 || idx >= quotes.length) return [];
                        final dt = quotes[idx].quote.capturadoEm.toLocal();
                        final head =
                            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
                            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                        // 3 linhas (Real/Modelo/Manual)
                        final real = quotes[idx].quote.brlPerUsd;
                        final model = quotes[idx].check.fxModel;
                        final manual = quotes[idx].check.fxManual;
                        return [
                          LineTooltipItem(
                            '$head\n',
                            const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          LineTooltipItem(
                            'Real: ${real.toStringAsFixed(4)}\n',
                            const TextStyle(),
                          ),
                          LineTooltipItem(
                            'Modelo: ${model.toStringAsFixed(4)}\n',
                            const TextStyle(),
                          ),
                          LineTooltipItem(
                            'Manual: ${manual.toStringAsFixed(4)}',
                            const TextStyle(),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: const [
                _LegendDot(label: 'Real (quote)', filled: true),
                _LegendDot(label: 'Modelo (check.fx_model)', filled: false),
                _LegendDot(label: 'Manual (check.fx_manual)', filled: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final bool filled;
  const _LegendDot({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          filled ? Icons.circle : Icons.circle_outlined,
          size: 12,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

// ---------------- List ----------------

class _ListCard extends StatelessWidget {
  final FxFuturesQuotesVM vm;
  final String Function(Object?) errMsg;
  const _ListCard({required this.vm, required this.errMsg});

  @override
  Widget build(BuildContext context) {
    if (vm.loading && vm.quotes.isEmpty) {
      return const Card(
        child: LoadingWidget(message: 'Carregando lançamentos...'),
      );
    }

    if (vm.error != null && vm.quotes.isEmpty) {
      return Card(
        child: ErrorRetryWidget(
          title: 'Erro ao carregar lançamentos',
          message: errMsg(vm.error),
          onRetry: () => vm.loadQuotesForSelected(),
        ),
      );
    }

    if (vm.quotes.isEmpty) {
      return const Card(
        child: EmptyStateWidget(
          title: 'Nenhum lançamento',
          message:
              'Este mês ainda não tem cotações. Use o formulário para lançar.',
          icon: Icons.edit_calendar,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lançamentos do mês',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: vm.quotes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final row = vm.quotes[i];
                  final dt = row.quote.capturadoEm.toLocal();
                  final dateLabel =
                      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(
                      'Real: ${row.quote.brlPerUsd.toStringAsFixed(4)}  •  Erro: ${row.check.deltaPct.toStringAsFixed(2)}%',
                    ),
                    subtitle: Text(
                      '$dateLabel'
                      '${row.quote.observacao != null ? ' • ${row.quote.observacao}' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Modelo: ${row.check.fxModel.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          'Manual: ${row.check.fxManual.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- small helpers ----------------

List<DateTime> _nextMonths({int count = 12}) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  return List.generate(count, (i) {
    final m = DateTime(start.year, start.month + i, 1);
    return m;
  });
}

String _fmtMonthLabel(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  return '${d.year}-$mm';
}

String _fmtN(double? v) => v == null ? '—' : v.toStringAsFixed(4);
String _fmtPct(double? v) => v == null ? '—' : '${v.toStringAsFixed(2)}%';

double? _min3(List<FlSpot> a, List<FlSpot> b, List<FlSpot> c) {
  final all = [...a, ...b, ...c];
  if (all.isEmpty) return null;
  return all.map((e) => e.y).reduce((x, y) => x < y ? x : y);
}

double? _max3(List<FlSpot> a, List<FlSpot> b, List<FlSpot> c) {
  final all = [...a, ...b, ...c];
  if (all.isEmpty) return null;
  return all.map((e) => e.y).reduce((x, y) => x > y ? x : y);
}
