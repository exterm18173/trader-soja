// contracts_result_dashboard_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/dashboard/contracts_result_dashboard_vm.dart';
import '../../widgets/common/empty_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/loading_widget.dart';

class ContractsResultDashboardScreen extends StatefulWidget {
  const ContractsResultDashboardScreen({super.key});

  @override
  State<ContractsResultDashboardScreen> createState() =>
      _ContractsResultDashboardScreenState();
}

class _ContractsResultDashboardScreenState
    extends State<ContractsResultDashboardScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ContractsResultDashboardVM>();
      vm.load();
      // Polling agora é controlado pelo setMode no VM (realtime liga / manual desliga)
      if (vm.mode == ContractPricingMode.realtime) {
        vm.startRealtimePolling(every: const Duration(seconds: 10));
      } else {
        vm.stopRealtimePolling();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    // Segurança extra se o VM for singleton acima do Navigator
    context.read<ContractsResultDashboardVM>().stopRealtimePolling();
    super.dispose();
  }

  void _onSearchChanged(ContractsResultDashboardVM vm, String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      vm.setSearch(v);
      vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContractsResultDashboardVM>(
      builder: (_, vm, __) {
        if (vm.loading && vm.contracts.isEmpty) {
          return const Scaffold(
            body: LoadingWidget(message: 'Carregando dashboard de contratos...'),
          );
        }

        if (vm.error != null && vm.contracts.isEmpty) {
          return Scaffold(
            body: ErrorRetryWidget(
              title: 'Erro ao carregar dashboard',
              message: vm.errorText(),
              onRetry: vm.load,
            ),
          );
        }

        final rows = vm.rows;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard • Resultado por Contrato'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SegmentedButton<ContractPricingMode>(
                  segments: const [
                    ButtonSegment(
                      value: ContractPricingMode.manual,
                      label: Text('Manual'),
                    ),
                    ButtonSegment(
                      value: ContractPricingMode.realtime,
                      label: Text('Tempo real'),
                    ),
                  ],
                  selected: {vm.mode},
                  onSelectionChanged: (s) {
                    final m = s.first;
                    vm.setMode(m);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Recarregar',
                onPressed: vm.load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // KPI cards
                _KpiRow(vm: vm),
                const SizedBox(height: 12),

                // Filters + info
                _TopBar(
                  searchCtrl: _searchCtrl,
                  onSearch: () {
                    vm.setSearch(_searchCtrl.text);
                    vm.load();
                  },
                  onClear: () {
                    _searchCtrl.clear();
                    vm.setSearch('');
                    vm.load();
                  },
                  onSearchChanged: (v) => _onSearchChanged(vm, v),
                  status: vm.statusFilter,
                  onStatus: (v) {
                    vm.setStatusFilter(v);
                    vm.load();
                  },
                  realtimeInfo: vm.realtimeInfo(),
                  isRealtime: vm.mode == ContractPricingMode.realtime,
                ),
                const SizedBox(height: 12),

                if (rows.isEmpty)
                  const Expanded(
                    child: Card(
                      child: EmptyStateWidget(
                        title: 'Sem contratos',
                        message: 'Crie contratos para ver os resultados aqui.',
                        icon: Icons.assignment_outlined,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _ContractsTable(
                          rows: rows,
                          mode: vm.mode,
                          manualInfo: vm.manualInfoFor,
                        ),
                      ),
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

// ---------------- KPI Row ----------------

class _KpiRow extends StatelessWidget {
  final ContractsResultDashboardVM vm;
  const _KpiRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final k = vm.kpis;

    return LayoutBuilder(
      builder: (_, c) {
        final isNarrow = c.maxWidth < 900;

        final items = <Widget>[
          _KpiCard(
            title: 'Contratos',
            value: k.contractsCount.toString(),
            icon: Icons.assignment_outlined,
          ),
          _KpiCard(
            title: 'Volume total (t)',
            value: k.totalTon.toStringAsFixed(2),
            icon: Icons.scale_outlined,
          ),
          _KpiCard(
            title: 'Resultado médio (BRL/saca)',
            value: k.avgBrlPerSack == null
                ? '—'
                : k.avgBrlPerSack!.toStringAsFixed(2),
            icon: Icons.trending_up_outlined,
          ),
          _KpiCard(
            title: '% travas (CBOT / Prem / FX)',
            value:
                '${(k.avgPctCbotLocked * 100).toStringAsFixed(0)}% / ${(k.avgPctPremiumLocked * 100).toStringAsFixed(0)}% / ${(k.avgPctFxLocked * 100).toStringAsFixed(0)}%',
            icon: Icons.lock_outline,
          ),
        ];

        if (isNarrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items
                .map((w) => SizedBox(width: (c.maxWidth - 12) / 2, child: w))
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 12),
            Expanded(child: items[1]),
            const SizedBox(width: 12),
            Expanded(child: items[2]),
            const SizedBox(width: 12),
            Expanded(child: items[3]),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 28, color: t.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: t.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Top Bar ----------------

class _TopBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String> onSearchChanged;
  final String? status;
  final ValueChanged<String?> onStatus;
  final String realtimeInfo;
  final bool isRealtime;

  const _TopBar({
    required this.searchCtrl,
    required this.onSearch,
    required this.onClear,
    required this.onSearchChanged,
    required this.status,
    required this.onStatus,
    required this.realtimeInfo,
    required this.isRealtime,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final searchField = TextField(
      controller: searchCtrl,
      decoration: InputDecoration(
        labelText: 'Buscar (id, observação...)',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Buscar',
              onPressed: onSearch,
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Limpar',
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
      ),
      onChanged: onSearchChanged,
      onSubmitted: (_) => onSearch(),
    );

    final statusField = DropdownButtonFormField<String>(
      value: status,
      items: const [
        DropdownMenuItem(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 'ABERTO', child: Text('ABERTO')),
        DropdownMenuItem(value: 'FECHADO', child: Text('FECHADO')),
        DropdownMenuItem(value: 'CANCELADO', child: Text('CANCELADO')),
      ],
      onChanged: onStatus,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );

    final infoBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: t.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isRealtime ? Icons.wifi_tethering : Icons.info_outline,
            size: 18,
            color: isRealtime ? t.colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              realtimeInfo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (_, c) {
        final isNarrow = c.maxWidth < 900;

        if (!isNarrow) {
          return Row(
            children: [
              Expanded(flex: 4, child: searchField),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: statusField),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: infoBox),
            ],
          );
        }

        // narrow
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: c.maxWidth, child: searchField),
            SizedBox(width: c.maxWidth, child: statusField),
            SizedBox(width: c.maxWidth, child: infoBox),
          ],
        );
      },
    );
  }
}

// ---------------- Table ----------------

enum _SortField { entrega, volume, usdSack, brlSack, cbotPct, premPct, fxPct }

class _ContractsTable extends StatefulWidget {
  final List<ContractResultRow> rows;
  final ContractPricingMode mode;
  final String Function(ContractResultRow) manualInfo;

  const _ContractsTable({
    required this.rows,
    required this.mode,
    required this.manualInfo,
  });

  @override
  State<_ContractsTable> createState() => _ContractsTableState();
}

class _ContractsTableState extends State<_ContractsTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  _SortField _field = _SortField.entrega;

  String _fmt(double? v, {int dec = 4}) => v == null ? '—' : v.toStringAsFixed(dec);
  String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';

  List<ContractResultRow> get _sorted {
    final list = [...widget.rows];

    int cmpNum(num? a, num? b) {
      final aa = a ?? -1e30;
      final bb = b ?? -1e30;
      return aa.compareTo(bb);
    }

    int cmpDate(DateTime a, DateTime b) => a.compareTo(b);

    int cmp(ContractResultRow a, ContractResultRow b) {
      switch (_field) {
        case _SortField.entrega:
          return cmpDate(a.contract.dataEntrega, b.contract.dataEntrega);
        case _SortField.volume:
          return a.volumeTotalTon.compareTo(b.volumeTotalTon);
        case _SortField.usdSack:
          return cmpNum(a.lockedUsdPerSack, b.lockedUsdPerSack);
        case _SortField.brlSack:
          final brlA = widget.mode == ContractPricingMode.manual
              ? a.lockedBrlPerSackManual
              : a.lockedBrlPerSackRealtime;
          final brlB = widget.mode == ContractPricingMode.manual
              ? b.lockedBrlPerSackManual
              : b.lockedBrlPerSackRealtime;
          return cmpNum(brlA, brlB);
        case _SortField.cbotPct:
          return a.pctCbotLocked.compareTo(b.pctCbotLocked);
        case _SortField.premPct:
          return a.pctPremiumLocked.compareTo(b.pctPremiumLocked);
        case _SortField.fxPct:
          return a.pctFxLocked.compareTo(b.pctFxLocked);
      }
    }

    list.sort((a, b) => _sortAscending ? cmp(a, b) : cmp(b, a));
    return list;
  }

  void _setSort(int columnIndex, _SortField field) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _field = field;
    });
  }

  void _openDetails(BuildContext context, ContractResultRow r) {
    final c = r.contract;
    final entrega =
        '${c.dataEntrega.day.toString().padLeft(2, '0')}/${c.dataEntrega.month.toString().padLeft(2, '0')}/${c.dataEntrega.year}';

    final brlSack = widget.mode == ContractPricingMode.manual
        ? r.lockedBrlPerSackManual
        : r.lockedBrlPerSackRealtime;

    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Contrato #${c.id} • ${c.produto}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${c.status}'),
                Text('Entrega: $entrega'),
                Text('Volume: ${c.volumeTotalTon.toStringAsFixed(2)} t'),
                const Divider(),
                Text('USD/saca travado: ${_fmt(r.lockedUsdPerSack, dec: 4)}'),
                Text('BRL/saca (${widget.mode.name}): ${_fmt(brlSack, dec: 2)}'),
                const SizedBox(height: 8),
                Text('Travas: ${_pct(r.pctCbotLocked)} / ${_pct(r.pctPremiumLocked)} / ${_pct(r.pctFxLocked)}'),
                const SizedBox(height: 12),
                Text(
                  widget.mode == ContractPricingMode.manual
                      ? 'Manual: ${widget.manualInfo(r)}'
                      : 'Realtime: FX ${_fmt(r.realtimeFxBrlPerUsd)} • CBOT ${_fmt(r.realtimeCbotUsdPerBu)}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sorted;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1200),
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          headingRowHeight: 44,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 64,
          columns: [
            const DataColumn(label: Text('Contrato')),
            DataColumn(
              label: const Text('Entrega'),
              onSort: (i, _) => _setSort(i, _SortField.entrega),
            ),
            DataColumn(
              label: const Text('Volume (t)'),
              numeric: true,
              onSort: (i, _) => _setSort(i, _SortField.volume),
            ),
            DataColumn(
              label: const Text('Travado USD/saca'),
              numeric: true,
              onSort: (i, _) => _setSort(i, _SortField.usdSack),
            ),
            DataColumn(
              label: Text('Resultado BRL/saca (${widget.mode.name})'),
              numeric: true,
              onSort: (i, _) => _setSort(i, _SortField.brlSack),
            ),
            DataColumn(
              label: const Text('CBOT/Prem/FX travado'),
              onSort: (i, _) => _setSort(i, _SortField.cbotPct),
            ),
            const DataColumn(label: Text('Info')),
          ],
          rows: rows.map((r) {
            final c = r.contract;
            final entrega =
                '${c.dataEntrega.day.toString().padLeft(2, '0')}/${c.dataEntrega.month.toString().padLeft(2, '0')}/${c.dataEntrega.year}';

            final brlSack = widget.mode == ContractPricingMode.manual
                ? r.lockedBrlPerSackManual
                : r.lockedBrlPerSackRealtime;

            final locks =
                '${_pct(r.pctCbotLocked)} / ${_pct(r.pctPremiumLocked)} / ${_pct(r.pctFxLocked)}';

            final info = widget.mode == ContractPricingMode.manual
                ? widget.manualInfo(r)
                : 'FX spot ${_fmt(r.realtimeFxBrlPerUsd)} • CBOT ${_fmt(r.realtimeCbotUsdPerBu)}';

            return DataRow(
              onSelectChanged: (_) => _openDetails(context, r),
              cells: [
                DataCell(Text('#${c.id} • ${c.produto} • ${c.status}')),
                DataCell(Text(entrega)),
                DataCell(Text(c.volumeTotalTon.toStringAsFixed(2))),
                DataCell(Text(_fmt(r.lockedUsdPerSack))),
                DataCell(
                  Text(
                    _fmt(brlSack, dec: 2),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: brlSack == null
                          ? null
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                DataCell(Text(locks)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(info, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
