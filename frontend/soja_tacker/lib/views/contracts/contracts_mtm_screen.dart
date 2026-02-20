import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/formatters/app_formatters.dart';
import '../../viewmodels/contracts/contracts_mtm_vm.dart';
import '../../data/models/contracts_mtm/contracts_mtm_response.dart';

import '../../widgets/common/empty_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/loading_widget.dart';

enum _ViewMode { cards, table }

class ContractsMtmScreen extends StatefulWidget {
  final int farmId;
  const ContractsMtmScreen({super.key, required this.farmId});

  @override
  State<ContractsMtmScreen> createState() => _ContractsMtmScreenState();
}

class _ContractsMtmScreenState extends State<ContractsMtmScreen> {
  final _refMesCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController(text: 'ZS=F');

  _ViewMode _viewMode = _ViewMode.table;
  bool _groupByRefMes = true;

  int? _sortColumnIndex;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ContractsMtmVM>();
      _refMesCtrl.text = vm.refMes ?? '';
      _symbolCtrl.text = vm.defaultSymbol;

      vm.load(farmId: widget.farmId);
      vm.startRealtimePolling(
        farmId: widget.farmId,
        every: const Duration(seconds: 10),
      );
    });
  }

  @override
  void dispose() {
    _refMesCtrl.dispose();
    _symbolCtrl.dispose();
    super.dispose();
  }

  String _dateYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  String _refMesLabel(DateTime? refMes) {
    if (refMes == null) return 'Sem ref_mes';
    final y = refMes.year.toString().padLeft(4, '0');
    final m = refMes.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  // -------------------------
  // Aggregations
  // -------------------------
  _AggTotals _computeAgg(List<ContractMtmRow> rows, String mode) {
    double usdTotal = 0.0;

    double brlTotalSystem = 0.0;
    double brlTotalManual = 0.0;
    bool hasBrlSystem = false;
    bool hasBrlManual = false;

    double ton = 0.0;
    double sacas = 0.0;

    for (final r in rows) {
      ton += r.totals.tonTotal;
      sacas += r.totals.sacasTotal;

      final u = r.totals.usdTotalContract;
      if (u != null) usdTotal += u;

      final bs = r.totals.brlTotalContract.system;
      final bm = r.totals.brlTotalContract.manual;

      if (bs != null) {
        brlTotalSystem += bs;
        hasBrlSystem = true;
      }
      if (bm != null) {
        brlTotalManual += bm;
        hasBrlManual = true;
      }
    }

    double? safeAvg(double? total, double denom) {
      if (total == null) return null;
      if (denom <= 0) return null;
      return total / denom;
    }

    final usdAvgPerSaca = safeAvg(usdTotal, sacas);
    final brlAvgPerSacaSystem = safeAvg(hasBrlSystem ? brlTotalSystem : null, sacas);
    final brlAvgPerSacaManual = safeAvg(hasBrlManual ? brlTotalManual : null, sacas);

    return _AggTotals(
      tonTotal: ton,
      sacasTotal: sacas,
      usdTotal: usdTotal,
      brlTotalSystem: hasBrlSystem ? brlTotalSystem : null,
      brlTotalManual: hasBrlManual ? brlTotalManual : null,
      usdAvgPerSaca: usdAvgPerSaca,
      brlAvgPerSacaSystem: brlAvgPerSacaSystem,
      brlAvgPerSacaManual: brlAvgPerSacaManual,
      mode: mode,
    );
  }

  Map<String, List<ContractMtmRow>> _groupRows(
    List<ContractMtmRow> rows,
    bool groupByRefMes,
  ) {
    if (!groupByRefMes) return {'Todos': rows};

    final map = <String, List<ContractMtmRow>>{};
    for (final r in rows) {
      final refMes = r.quotes.fxSystem?.refMes ?? r.quotes.fxManual?.refMes ?? r.locks.cbot.refMes;
      final key = _refMesLabel(refMes);
      map.putIfAbsent(key, () => []).add(r);
    }

    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]!};
  }

  // -------------------------
  // Sorting (table)
  // -------------------------
  List<ContractMtmRow> _sortedRows(
    List<ContractMtmRow> rows,
    int? col,
    bool asc,
    String mode,
  ) {
    if (col == null) return rows;

    double numOr0(double? v) => v ?? double.negativeInfinity;

    double? usdSaca(ContractMtmRow r) =>
        (mode == 'manual') ? r.valuation.usdPerSaca.manual : r.valuation.usdPerSaca.system;

    double? brlSaca(ContractMtmRow r) =>
        (mode == 'manual') ? r.valuation.brlPerSaca.manual : r.valuation.brlPerSaca.system;

    double? brlTot(ContractMtmRow r) =>
        (mode == 'manual') ? r.totals.brlTotalContract.manual : r.totals.brlTotalContract.system;

    final list = [...rows];

    int cmp(ContractMtmRow a, ContractMtmRow b) {
      int c = 0;
      switch (col) {
        case 0:
          c = a.contract.id.compareTo(b.contract.id);
          break;
        case 1:
          c = a.contract.dataEntrega.compareTo(b.contract.dataEntrega);
          break;
        case 2:
          c = numOr0(usdSaca(a)).compareTo(numOr0(usdSaca(b)));
          break;
        case 3:
          c = numOr0(brlSaca(a)).compareTo(numOr0(brlSaca(b)));
          break;
        case 4:
          c = numOr0(a.totals.usdTotalContract).compareTo(numOr0(b.totals.usdTotalContract));
          break;
        case 5:
          c = numOr0(brlTot(a)).compareTo(numOr0(brlTot(b)));
          break;
        case 6:
          final p = (mode == 'manual') ? a.totals.fxLockedUsdPct.manual : a.totals.fxLockedUsdPct.system;
          final q = (mode == 'manual') ? b.totals.fxLockedUsdPct.manual : b.totals.fxLockedUsdPct.system;
          c = numOr0(p).compareTo(numOr0(q));
          break;
        case 7:
          c = _alertSeverity(a).compareTo(_alertSeverity(b));
          break;
        default:
          c = 0;
      }
      return asc ? c : -c;
    }

    list.sort(cmp);
    return list;
  }

  // -------------------------
  // Alerts
  // -------------------------
  int _alertSeverity(ContractMtmRow r) {
    final cbotLocked = r.locks.cbot.locked;
    final premLocked = r.locks.premium.locked;

    final fxLocked = r.locks.fx.locked;
    final hasFxSys = r.quotes.fxSystem != null;
    final hasFxMan = r.quotes.fxManual != null;

    if (!hasFxSys && !hasFxMan && r.valuation.usdPerSaca.system != null) return 2;
    if (cbotLocked && !premLocked) return 1;
    if (!fxLocked && (hasFxSys || hasFxMan)) return 1;

    return 0;
  }

  List<_AlertTag> _alertTags(ContractMtmRow r) {
    final tags = <_AlertTag>[];

    final cbotLocked = r.locks.cbot.locked;
    final premLocked = r.locks.premium.locked;

    final fxLocked = r.locks.fx.locked;
    final hasFxSys = r.quotes.fxSystem != null;
    final hasFxMan = r.quotes.fxManual != null;

    if (!hasFxSys && !hasFxMan) {
      tags.add(const _AlertTag('Sem FX (BRL indisponível)', _AlertLevel.critical));
    }
    if (cbotLocked && !premLocked) {
      tags.add(const _AlertTag('Prêmio não travado', _AlertLevel.warn));
    }
    if (!fxLocked && (hasFxSys || hasFxMan)) {
      tags.add(const _AlertTag('FX não travado', _AlertLevel.warn));
    }

    return tags;
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    final themed = base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );

    return Theme(
      data: themed,
      child: Consumer<ContractsMtmVM>(
        builder: (_, vm, __) {
          if (vm.loading && vm.data == null) {
            return const Scaffold(
              body: Center(child: LoadingWidget(message: 'Carregando MTM...')),
            );
          }

          if (vm.error != null && vm.data == null) {
            return Scaffold(
              body: Center(
                child: ErrorRetryWidget(
                  title: 'Erro ao carregar MTM',
                  message: vm.errMsg(vm.error),
                  onRetry: () => vm.load(farmId: widget.farmId),
                ),
              ),
            );
          }

          final data = vm.data;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Contratos • MTM (tempo real)'),
              actions: [
                if (vm.loading)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: 'Atualizar agora',
                  onPressed: () => vm.load(farmId: widget.farmId),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: Column(
              children: [
                _FiltersBar(
                  mode: vm.mode,
                  onlyOpen: vm.onlyOpen,
                  viewMode: _viewMode,
                  groupByRefMes: _groupByRefMes,
                  refMesCtrl: _refMesCtrl,
                  symbolCtrl: _symbolCtrl,
                  onModeChanged: (v) => vm.setMode(v, farmId: widget.farmId),
                  onToggleOnlyOpen: () => vm.toggleOnlyOpen(farmId: widget.farmId),
                  onApplyRefMes: () => vm.setRefMes(_refMesCtrl.text, farmId: widget.farmId),
                  onApplySymbol: () => vm.setDefaultSymbol(_symbolCtrl.text, farmId: widget.farmId),
                  onChangeViewMode: (m) => setState(() => _viewMode = m),
                  onToggleGroup: () => setState(() => _groupByRefMes = !_groupByRefMes),
                ),

                if (data != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Atualizado: ${data.asOfTs.toLocal()}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rows: ${AppFormatters.intN(data.rows.length)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                if (data != null && data.rows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _TotalsHeader(
                      totals: _computeAgg(data.rows, vm.mode),
                    ),
                  ),

                Expanded(
                  child: (data == null || data.rows.isEmpty)
                      ? const EmptyStateWidget(
                          title: 'Nenhum contrato',
                          message: 'Não há contratos para mostrar com os filtros atuais.',
                        )
                      : RefreshIndicator(
                          onRefresh: () => vm.load(farmId: widget.farmId),
                          child: _buildBody(
                            context: context,
                            vm: vm,
                            rows: data.rows,
                          ),
                        ),
                ),

                if (vm.error != null && data != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _InlineError(
                      message: vm.errMsg(vm.error),
                      onRetry: () => vm.load(farmId: widget.farmId),
                    ),
                  ),

                SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 6),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ContractsMtmVM vm,
    required List<ContractMtmRow> rows,
  }) {
    final grouped = _groupRows(rows, _groupByRefMes);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: grouped.length,
      itemBuilder: (_, idx) {
        final key = grouped.keys.elementAt(idx);
        final groupRows = grouped[key]!;
        final groupTotals = _computeAgg(groupRows, vm.mode);

        final groupSorted = _sortedRows(groupRows, _sortColumnIndex, _sortAsc, vm.mode);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _GroupSection(
            title: key,
            subtitle: 'Contratos: ${AppFormatters.intN(groupRows.length)}',
            totals: groupTotals,
            child: _viewMode == _ViewMode.cards
                ? _CardsList(
                    rows: groupSorted,
                    mode: vm.mode,
                    dateYmd: _dateYmd,
                    alertTags: _alertTags,
                  )
                : _TableView(
                    rows: groupSorted,
                    mode: vm.mode,
                    dateYmd: _dateYmd,
                    alertSeverity: _alertSeverity,
                    alertTags: _alertTags,
                    sortColumnIndex: _sortColumnIndex,
                    sortAsc: _sortAsc,
                    onSort: (col, asc) => setState(() {
                      _sortColumnIndex = col;
                      _sortAsc = asc;
                    }),
                  ),
          ),
        );
      },
    );
  }
}

// =====================================================
// Widgets
// =====================================================

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.errorContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final String mode;
  final bool onlyOpen;

  final _ViewMode viewMode;
  final bool groupByRefMes;

  final TextEditingController refMesCtrl;
  final TextEditingController symbolCtrl;

  final ValueChanged<String> onModeChanged;
  final VoidCallback onToggleOnlyOpen;
  final VoidCallback onApplyRefMes;
  final VoidCallback onApplySymbol;

  final ValueChanged<_ViewMode> onChangeViewMode;
  final VoidCallback onToggleGroup;

  const _FiltersBar({
    required this.mode,
    required this.onlyOpen,
    required this.viewMode,
    required this.groupByRefMes,
    required this.refMesCtrl,
    required this.symbolCtrl,
    required this.onModeChanged,
    required this.onToggleOnlyOpen,
    required this.onApplyRefMes,
    required this.onApplySymbol,
    required this.onChangeViewMode,
    required this.onToggleGroup,
  });

  void _openFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: cs.primary),
                  const SizedBox(width: 10),
                  Text('Filtros avançados', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: refMesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ref_mes (YYYY-MM-01) opcional',
                  prefixIcon: Icon(Icons.calendar_month),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: symbolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Symbol default (ex: ZS=F)',
                  prefixIcon: Icon(Icons.show_chart),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        onApplyRefMes();
                        onApplySymbol();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Fechar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'system', label: Text('System')),
                ButtonSegment(value: 'manual', label: Text('Manual')),
                ButtonSegment(value: 'both', label: Text('Both')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => onModeChanged(s.first),
            ),
            FilterChip(
              selected: onlyOpen,
              onSelected: (_) => onToggleOnlyOpen(),
              label: const Text('Abertos'),
            ),
            SegmentedButton<_ViewMode>(
              segments: const [
                ButtonSegment(value: _ViewMode.table, label: Text('Tabela')),
                ButtonSegment(value: _ViewMode.cards, label: Text('Cards')),
              ],
              selected: {viewMode},
              onSelectionChanged: (s) => onChangeViewMode(s.first),
            ),
            FilterChip(
              selected: groupByRefMes,
              onSelected: (_) => onToggleGroup(),
              label: const Text('Agrupar ref_mes'),
            ),
            ActionChip(
              avatar: const Icon(Icons.tune, size: 18),
              label: const Text('Filtros'),
              onPressed: () => _openFiltersSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final _AggTotals totals;
  final Widget child;

  const _GroupSection({
    required this.title,
    required this.subtitle,
    required this.totals,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 10),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            _TotalsMini(totals: totals),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CardsList extends StatelessWidget {
  final List<ContractMtmRow> rows;
  final String mode;
  final String Function(DateTime d) dateYmd;
  final List<_AlertTag> Function(ContractMtmRow r) alertTags;

  const _CardsList({
    required this.rows,
    required this.mode,
    required this.dateYmd,
    required this.alertTags,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in rows) ...[
          _ContractCard(
            row: r,
            mode: mode,
            dateYmd: dateYmd,
            alertTags: alertTags,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractMtmRow row;
  final String mode;
  final String Function(DateTime d) dateYmd;
  final List<_AlertTag> Function(ContractMtmRow r) alertTags;

  const _ContractCard({
    required this.row,
    required this.mode,
    required this.dateYmd,
    required this.alertTags,
  });

  double? _side(double? system, double? manual) => (mode == 'manual') ? manual : system;

  @override
  Widget build(BuildContext context) {
    final c = row.contract;

    final usdSaca = _side(row.valuation.usdPerSaca.system, row.valuation.usdPerSaca.manual);
    final brlSaca = _side(row.valuation.brlPerSaca.system, row.valuation.brlPerSaca.manual);
    final brlTot = _side(row.totals.brlTotalContract.system, row.totals.brlTotalContract.manual);

    final fxLockedPct = _side(row.totals.fxLockedUsdPct.system, row.totals.fxLockedUsdPct.manual);
    final fxMode = (mode == 'manual') ? row.totals.fxLockMode.manual : row.totals.fxLockMode.system;

    final tags = alertTags(row);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Text('Contrato #${c.id}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              _StatusPill(text: c.status),
              const Spacer(),
              Text(dateYmd(c.dataEntrega), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),

          if (tags.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) => _AlertChip(tag: t)).toList(),
              ),
            ),

          if (tags.isNotEmpty) const SizedBox(height: 12),

          // linhas “grid” mais responsivas
          _KvGrid(
            items: [
              _KvItem('USD/saca', AppFormatters.usdPerSaca(usdSaca), Icons.attach_money),
              _KvItem('BRL/saca', AppFormatters.brlPerSaca(brlSaca), Icons.currency_exchange),
              _KvItem('USD total', AppFormatters.usd(row.totals.usdTotalContract), Icons.account_balance_wallet),
              _KvItem('BRL total', AppFormatters.brl(brlTot), Icons.account_balance),
              _KvItem('FX travado', AppFormatters.pct(fxLockedPct, decimals: 1), Icons.lock),
              _KvItem('FX mode', fxMode, Icons.tune),
              _KvItem('CBOT lock', row.locks.cbot.locked ? 'sim' : 'não', Icons.check_circle),
              _KvItem('Prêmio lock', row.locks.premium.locked ? 'sim' : 'não', Icons.workspace_premium),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  final List<ContractMtmRow> rows;
  final String mode;

  final String Function(DateTime d) dateYmd;

  final int Function(ContractMtmRow r) alertSeverity;
  final List<_AlertTag> Function(ContractMtmRow r) alertTags;

  final int? sortColumnIndex;
  final bool sortAsc;
  final void Function(int col, bool asc) onSort;

  const _TableView({
    required this.rows,
    required this.mode,
    required this.dateYmd,
    required this.alertSeverity,
    required this.alertTags,
    required this.sortColumnIndex,
    required this.sortAsc,
    required this.onSort,
  });

  double? _side(double? system, double? manual) => (mode == 'manual') ? manual : system;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 980),
            child: DataTableTheme(
              data: DataTableThemeData(
                headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                dividerThickness: 0.8,
              ),
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 18,
                horizontalMargin: 14,
                headingRowHeight: 42,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAsc,
                columns: [
                  DataColumn(label: const Text('ID'), numeric: true, onSort: (i, asc) => onSort(i, asc)),
                  DataColumn(label: const Text('Entrega'), onSort: (i, asc) => onSort(i, asc)),
                  DataColumn(label: const Text('USD/saca'), numeric: true, onSort: (i, asc) => onSort(i, asc)),
                  DataColumn(label: const Text('BRL/saca'), numeric: true, onSort: (i, asc) => onSort(i, asc)),
                  DataColumn(label: const Text('USD total'), numeric: true, onSort: (i, asc) => onSort(i, asc)),
                  DataColumn(label: const Text('BRL total'), numeric: true, onSort: (i, asc) => onSort(i, asc)),
                  DataColumn(label: const Text('FX travado'), numeric: true, onSort: (i, asc) => onSort(i, asc)),
                  DataColumn(label: const Text('Alertas'), onSort: (i, asc) => onSort(i, asc)),
                ],
                rows: rows.map((r) {
                  final sev = alertSeverity(r);
                  final tags = alertTags(r);

                  final bg = sev == 2
                      ? cs.errorContainer.withValues(alpha: 0.35)
                      : sev == 1
                          ? cs.tertiaryContainer.withValues(alpha: 0.25)
                          : null;

                  final usdSaca = _side(r.valuation.usdPerSaca.system, r.valuation.usdPerSaca.manual);
                  final brlSaca = _side(r.valuation.brlPerSaca.system, r.valuation.brlPerSaca.manual);

                  final brlTot = _side(r.totals.brlTotalContract.system, r.totals.brlTotalContract.manual);
                  final fxPct = _side(r.totals.fxLockedUsdPct.system, r.totals.fxLockedUsdPct.manual);

                  return DataRow(
                    color: bg == null ? null : WidgetStatePropertyAll(bg),
                    cells: [
                      DataCell(Text('${r.contract.id}')),
                      DataCell(Text(dateYmd(r.contract.dataEntrega))),
                      DataCell(Text(AppFormatters.usdPerSaca(usdSaca))),
                      DataCell(Text(AppFormatters.brlPerSaca(brlSaca))),
                      DataCell(Text(AppFormatters.usd(r.totals.usdTotalContract))),
                      DataCell(Text(AppFormatters.brl(brlTot))),
                      DataCell(Text(AppFormatters.pct(fxPct, decimals: 1))),
                      DataCell(
                        tags.isEmpty
                            ? const Text('-')
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: tags.map((t) => _AlertChip(tag: t, dense: true)).toList(),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  final _AggTotals totals;

  const _TotalsHeader({required this.totals});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // lista de KPIs (fica fácil adicionar/remover)
    final kpis = <_KpiData>[
      _KpiData('Ton', AppFormatters.ton(totals.tonTotal), Icons.scale),
      _KpiData('Sacas', AppFormatters.sacas(totals.sacasTotal), Icons.inventory_2),
      _KpiData('USD total', AppFormatters.usd(totals.usdTotal), Icons.attach_money),
      _KpiData('BRL total (sys)', AppFormatters.brl(totals.brlTotalSystem), Icons.currency_exchange),
      _KpiData('BRL total (man)', AppFormatters.brl(totals.brlTotalManual), Icons.currency_exchange_outlined),
      _KpiData('USD médio/saca', AppFormatters.usdPerSaca(totals.usdAvgPerSaca), Icons.show_chart),
      _KpiData('BRL médio/saca (sys)', AppFormatters.brlPerSaca(totals.brlAvgPerSacaSystem), Icons.trending_up),
      _KpiData('BRL médio/saca (man)', AppFormatters.brlPerSaca(totals.brlAvgPerSacaManual), Icons.trending_up),
    ];

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _KpiGrid(items: kpis),
      ),
    );
  }
}

class _TotalsMini extends StatelessWidget {
  final _AggTotals totals;

  const _TotalsMini({required this.totals});

  @override
  Widget build(BuildContext context) {
    return _KpiGrid(
      dense: true,
      items: [
        _KpiData('USD', AppFormatters.usd(totals.usdTotal), Icons.attach_money),
        _KpiData('BRL sys', AppFormatters.brl(totals.brlTotalSystem), Icons.currency_exchange),
        _KpiData('BRL man', AppFormatters.brl(totals.brlTotalManual), Icons.currency_exchange_outlined),
        _KpiData('Ton', AppFormatters.ton(totals.tonTotal), Icons.scale),
        _KpiData('Sacas', AppFormatters.sacas(totals.sacasTotal), Icons.inventory_2),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

// ----------------- Alerts -----------------

enum _AlertLevel { warn, critical }

class _AlertTag {
  final String text;
  final _AlertLevel level;
  const _AlertTag(this.text, this.level);
}

class _AlertChip extends StatelessWidget {
  final _AlertTag tag;
  final bool dense;

  const _AlertChip({
    required this.tag,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = tag.level == _AlertLevel.critical;
    final cs = Theme.of(context).colorScheme;

    final bg = isCritical ? cs.errorContainer : cs.tertiaryContainer;
    final fg = isCritical ? cs.onErrorContainer : cs.onTertiaryContainer;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: dense ? 0.75 : 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag.text,
        style: TextStyle(
          color: fg,
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ----------------- KPI GRID (reutilizável) -----------------

class _KpiData {
  final String label;
  final String value;
  final IconData icon;

  const _KpiData(this.label, this.value, this.icon);
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiData> items;
  final bool dense;

  const _KpiGrid({
    required this.items,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // Responsivo: quanto maior a tela, mais colunas.
        int crossAxisCount = 2;
        if (w >= 520) crossAxisCount = 3;
        if (w >= 820) crossAxisCount = 4;

        final spacing = dense ? 8.0 : 10.0;
        final aspect = dense ? 2.8 : 2.3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspect,
          ),
          itemBuilder: (_, i) => _KpiCard(data: items[i], dense: dense),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final bool dense;

  const _KpiCard({
    required this.data,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(dense ? 10 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surface.withValues(alpha: 0.6),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: dense ? 34 : 38,
            height: dense ? 34 : 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cs.primaryContainer.withValues(alpha: 0.75),
            ),
            child: Icon(data.icon, color: cs.onPrimaryContainer, size: dense ? 18 : 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 11 : 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- KV GRID (cards) -----------------

class _KvItem {
  final String label;
  final String value;
  final IconData icon;

  const _KvItem(this.label, this.value, this.icon);
}

class _KvGrid extends StatelessWidget {
  final List<_KvItem> items;

  const _KvGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        int cols = 2;
        if (w >= 520) cols = 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (_, i) => _KvTile(item: items[i]),
        );
      },
    );
  }
}

class _KvTile extends StatelessWidget {
  final _KvItem item;

  const _KvTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Agg model -----------------

class _AggTotals {
  final double tonTotal;
  final double sacasTotal;
  final double usdTotal;
  final double? brlTotalSystem;
  final double? brlTotalManual;

  final double? usdAvgPerSaca;
  final double? brlAvgPerSacaSystem;
  final double? brlAvgPerSacaManual;

  final String mode;

  _AggTotals({
    required this.tonTotal,
    required this.sacasTotal,
    required this.usdTotal,
    required this.brlTotalSystem,
    required this.brlTotalManual,
    required this.usdAvgPerSaca,
    required this.brlAvgPerSacaSystem,
    required this.brlAvgPerSacaManual,
    required this.mode,
  });
}
