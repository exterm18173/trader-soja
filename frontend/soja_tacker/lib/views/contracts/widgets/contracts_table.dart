// lib/views/contracts_mtm_dashboard/widgets/contracts_table.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart';
import '../../../data/models/contracts_mtm/contracts_mtm_response.dart';

typedef OnContractAction = void Function(ContractMtmRow row, String action);

enum ContractsSortColumn {
  contractId,
  entrega,
  volumeTon,
  usdSaca,
  brlSaca,
  totalUsd,
  totalBrl,
}

class TableSort {
  final ContractsSortColumn column;
  final bool ascending;
  const TableSort({required this.column, required this.ascending});
}

class ContractsTable extends StatefulWidget {
  final List<ContractMtmRow> rows;

  final LockStatusUi Function(ContractMtmRow r) cbotUi;
  final LockStatusUi Function(ContractMtmRow r) premUi;
  final LockStatusUi Function(ContractMtmRow r) fxUi;

  final double Function(ContractMtmRow r) brlOf;
  final double Function(ContractMtmRow r) usdOf;

  final TableSort initialSort;
  final OnContractAction onAction;

  /// opcional: passe vm.updateTick pra garantir ciclo de atualização previsível
  final int? updateTick;

  const ContractsTable({
    super.key,
    required this.rows,
    required this.cbotUi,
    required this.premUi,
    required this.fxUi,
    required this.brlOf,
    required this.usdOf,
    required this.initialSort,
    required this.onAction,
    this.updateTick,
  });

  @override
  State<ContractsTable> createState() => _ContractsTableState();
}

class _ContractsTableState extends State<ContractsTable> {
  late ContractsSortColumn _sortCol;
  late bool _asc;

  final _searchCtrl = TextEditingController();
  bool _showOnlyOpen = false;

  // ✅ cache de valores anteriores por contrato (para flash por célula)
  final Map<int, _RowSnapshot> _prev = {};

  @override
  void initState() {
    super.initState();
    _sortCol = widget.initialSort.column;
    _asc = widget.initialSort.ascending;
    _seedPrev(widget.rows);
  }

  @override
  void didUpdateWidget(covariant ContractsTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Atualiza snapshot anterior *depois* que renderizamos novos valores?
    // Para flash funcionar bem, a gente mantém no cache o "antes"
    // e só sobrescreve quando detecta que já comparou (feito dentro do FlashCell via prevValue).
    // Aqui: apenas garante chaves existentes e remove contratos que sumiram.
    final idsNow = widget.rows.map((e) => e.contract.id).toSet();
    _prev.removeWhere((id, _) => !idsNow.contains(id));

    // Garante que contratos novos entrem com valores atuais (sem flash inicial)
    for (final r in widget.rows) {
      final id = r.contract.id;
      _prev.putIfAbsent(id, () => _snapshotOf(r));
    }
  }

  void _seedPrev(List<ContractMtmRow> rows) {
    for (final r in rows) {
      _prev[r.contract.id] = _snapshotOf(r);
    }
  }

  _RowSnapshot _snapshotOf(ContractMtmRow r) {
    final usdSaca = (r.valuation.usdPerSaca.manual ?? r.valuation.usdPerSaca.system ?? 0.0);
    final brlSaca = (r.valuation.brlPerSaca.manual ?? r.valuation.brlPerSaca.system ?? 0.0);

    return _RowSnapshot(
      ton: r.totals.tonTotal,
      sacas: r.totals.sacasTotal,
      usdSaca: usdSaca,
      brlSaca: brlSaca,
      totalUsd: widget.usdOf(r),
      totalBrl: widget.brlOf(r),
      cbotPct: widget.cbotUi(r).coveragePct,
      premPct: widget.premUi(r).coveragePct,
      fxPct: widget.fxUi(r).coveragePct,
    );
  }

  void _commitSnapshot(int contractId, _RowSnapshot next) {
    _prev[contractId] = next;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final df = DateFormat('dd/MM/yyyy');
    final border = cs.outlineVariant.withValues(alpha: 0.55);

    // --- Filter ---
    final q = _searchCtrl.text.trim().toLowerCase();

    bool matchesQuery(ContractMtmRow r) {
      if (q.isEmpty) return true;
      final c = r.contract;
      final entrega = df.format(c.dataEntrega).toLowerCase();
      final id = c.id.toString();
      return id.contains(q) || entrega.contains(q) || ('#$id').contains(q);
    }

    bool matchesOpenOnly(ContractMtmRow r) {
      if (!_showOnlyOpen) return true;
      final fx = widget.fxUi(r);
      return (fx.coveragePct.isFinite ? fx.coveragePct : 0.0) < 1.0;
    }

    final filtered = widget.rows.where((r) => matchesQuery(r) && matchesOpenOnly(r)).toList();

    // --- Sort ---
    filtered.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case ContractsSortColumn.contractId:
          cmp = a.contract.id.compareTo(b.contract.id);
          break;
        case ContractsSortColumn.entrega:
          cmp = a.contract.dataEntrega.compareTo(b.contract.dataEntrega);
          break;
        case ContractsSortColumn.volumeTon:
          cmp = a.totals.tonTotal.compareTo(b.totals.tonTotal);
          break;
        case ContractsSortColumn.usdSaca:
          final au = (a.valuation.usdPerSaca.manual ?? a.valuation.usdPerSaca.system ?? 0.0);
          final bu = (b.valuation.usdPerSaca.manual ?? b.valuation.usdPerSaca.system ?? 0.0);
          cmp = au.compareTo(bu);
          break;
        case ContractsSortColumn.brlSaca:
          final ab = (a.valuation.brlPerSaca.manual ?? a.valuation.brlPerSaca.system ?? 0.0);
          final bb = (b.valuation.brlPerSaca.manual ?? b.valuation.brlPerSaca.system ?? 0.0);
          cmp = ab.compareTo(bb);
          break;
        case ContractsSortColumn.totalUsd:
          cmp = widget.usdOf(a).compareTo(widget.usdOf(b));
          break;
        case ContractsSortColumn.totalBrl:
          cmp = widget.brlOf(a).compareTo(widget.brlOf(b));
          break;
      }
      return _asc ? cmp : -cmp;
    });

    // --- Summary ---
    final totalUsd = filtered.fold<double>(
      0.0,
      (p, r) => p + ((widget.usdOf(r).isFinite) ? widget.usdOf(r) : 0.0),
    );
    final totalBrl = filtered.fold<double>(
      0.0,
      (p, r) => p + ((widget.brlOf(r).isFinite) ? widget.brlOf(r) : 0.0),
    );

    final isCompact = MediaQuery.of(context).size.width < 760;

    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Controls
            Row(
              children: [
                _HeaderIcon(icon: Icons.table_chart_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Contratos',
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                if (!isCompact)
                  _SummaryPill(
                    text: '${filtered.length} itens • ${AppFormatters.usd(totalUsd)} • ${AppFormatters.brl(totalBrl)}',
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Search + Toggle
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ControlsRow(
                    searchCtrl: _searchCtrl,
                    showOnlyOpen: _showOnlyOpen,
                    onToggleOpen: (v) => setState(() => _showOnlyOpen = v),
                    onClear: () => setState(() => _searchCtrl.clear()),
                  ),
                  const SizedBox(height: 10),
                  _SummaryPill(
                    text: '${filtered.length} itens • ${AppFormatters.usd(totalUsd)} • ${AppFormatters.brl(totalBrl)}',
                  ),
                ],
              )
            else
              _ControlsRow(
                searchCtrl: _searchCtrl,
                showOnlyOpen: _showOnlyOpen,
                onToggleOpen: (v) => setState(() => _showOnlyOpen = v),
                onClear: () => setState(() => _searchCtrl.clear()),
              ),

            const SizedBox(height: 12),

            if (filtered.isEmpty)
              _EmptyState(
                title: 'Nenhum contrato encontrado',
                subtitle: 'Ajuste a busca ou desligue “Somente abertos”.',
              )
            else
              isCompact
                  ? _CompactList(
                      rows: filtered,
                      df: df,
                      cbotUi: widget.cbotUi,
                      premUi: widget.premUi,
                      fxUi: widget.fxUi,
                      brlOf: widget.brlOf,
                      usdOf: widget.usdOf,
                      onAction: widget.onAction,
                      prev: _prev,
                      commit: _commitSnapshot,
                      snapOf: _snapshotOf,
                    )
                  : _WideTable(
                      rows: filtered,
                      df: df,
                      asc: _asc,
                      sortCol: _sortCol,
                      onSort: (c) => _setSort(c),
                      colIndex: _colIndex,
                      cbotUi: widget.cbotUi,
                      premUi: widget.premUi,
                      fxUi: widget.fxUi,
                      brlOf: widget.brlOf,
                      usdOf: widget.usdOf,
                      onAction: widget.onAction,
                      prev: _prev,
                      commit: _commitSnapshot,
                      snapOf: _snapshotOf,
                    ),
          ],
        ),
      ),
    );
  }

  int _colIndex(ContractsSortColumn c) {
    switch (c) {
      case ContractsSortColumn.contractId:
        return 0;
      case ContractsSortColumn.entrega:
        return 1;
      case ContractsSortColumn.volumeTon:
        return 2;
      case ContractsSortColumn.usdSaca:
        return 3;
      case ContractsSortColumn.brlSaca:
        return 4;
      case ContractsSortColumn.totalUsd:
        return 5;
      case ContractsSortColumn.totalBrl:
        return 6;
    }
  }

  void _setSort(ContractsSortColumn col) {
    setState(() {
      if (_sortCol == col) {
        _asc = !_asc;
      } else {
        _sortCol = col;
        _asc = true;
      }
    });
  }
}

// ---------------- WIDE TABLE ----------------

class _WideTable extends StatelessWidget {
  final List<ContractMtmRow> rows;
  final DateFormat df;

  final bool asc;
  final ContractsSortColumn sortCol;
  final void Function(ContractsSortColumn col) onSort;
  final int Function(ContractsSortColumn c) colIndex;

  final LockStatusUi Function(ContractMtmRow r) cbotUi;
  final LockStatusUi Function(ContractMtmRow r) premUi;
  final LockStatusUi Function(ContractMtmRow r) fxUi;

  final double Function(ContractMtmRow r) brlOf;
  final double Function(ContractMtmRow r) usdOf;

  final OnContractAction onAction;

  final Map<int, _RowSnapshot> prev;
  final void Function(int id, _RowSnapshot next) commit;
  final _RowSnapshot Function(ContractMtmRow r) snapOf;

  const _WideTable({
    required this.rows,
    required this.df,
    required this.asc,
    required this.sortCol,
    required this.onSort,
    required this.colIndex,
    required this.cbotUi,
    required this.premUi,
    required this.fxUi,
    required this.brlOf,
    required this.usdOf,
    required this.onAction,
    required this.prev,
    required this.commit,
    required this.snapOf,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortAscending: asc,
            sortColumnIndex: colIndex(sortCol),
            headingRowHeight: 46,
            dataRowMinHeight: 46,
            columnSpacing: 22,
            horizontalMargin: 12,
            headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
            columns: [
              DataColumn(label: const Text('Contrato'), onSort: (_, __) => onSort(ContractsSortColumn.contractId)),
              DataColumn(label: const Text('Entrega'), onSort: (_, __) => onSort(ContractsSortColumn.entrega)),
              DataColumn(label: const Text('Volume'), numeric: true, onSort: (_, __) => onSort(ContractsSortColumn.volumeTon)),
              DataColumn(label: const Text('USD / Saca'), numeric: true, onSort: (_, __) => onSort(ContractsSortColumn.usdSaca)),
              DataColumn(label: const Text('BRL / Saca'), numeric: true, onSort: (_, __) => onSort(ContractsSortColumn.brlSaca)),
              DataColumn(label: const Text('Total USD'), numeric: true, onSort: (_, __) => onSort(ContractsSortColumn.totalUsd)),
              DataColumn(label: const Text('Total BRL'), numeric: true, onSort: (_, __) => onSort(ContractsSortColumn.totalBrl)),
              const DataColumn(label: Text('CBOT')),
              const DataColumn(label: Text('Prêmio')),
              const DataColumn(label: Text('FX')),
              const DataColumn(label: Text('Ações')),
            ],
            rows: rows.map((r) {
              final c = r.contract;
              final id = c.id;

              final usdSaca = r.valuation.usdPerSaca.manual ?? r.valuation.usdPerSaca.system;
              final brlSaca = r.valuation.brlPerSaca.manual ?? r.valuation.brlPerSaca.system;

              final uiC = cbotUi(r);
              final uiP = premUi(r);
              final uiF = fxUi(r);

              final prevSnap = prev[id];
              final nextSnap = snapOf(r);

              // Após construir a linha, atualiza cache (próximo ciclo vira "antes")
              WidgetsBinding.instance.addPostFrameCallback((_) {
                commit(id, nextSnap);
              });

              return DataRow(
                onSelectChanged: (_) => onAction(r, 'detalhar'),
                cells: [
                  DataCell(Text('#$id')),
                  DataCell(Text(df.format(c.dataEntrega))),

                  DataCell(
                    _FlashCell.text(
                      id: 'vol-$id',
                      prevText: prevSnap == null ? null : '${AppFormatters.ton(prevSnap.ton, decimals: 0)} t / ${AppFormatters.sacas(prevSnap.sacas)} sc',
                      text: '${AppFormatters.ton(r.totals.tonTotal, decimals: 0)} t / ${AppFormatters.sacas(r.totals.sacasTotal)} sc',
                    ),
                  ),

                  DataCell(
                    _FlashCell.num(
                      id: 'usdsc-$id',
                      prev: prevSnap?.usdSaca,
                      value: (usdSaca ?? 0.0),
                      fmt: AppFormatters.usd,
                    ),
                  ),
                  DataCell(
                    _FlashCell.num(
                      id: 'brlsc-$id',
                      prev: prevSnap?.brlSaca,
                      value: (brlSaca ?? 0.0),
                      fmt: AppFormatters.brl,
                    ),
                  ),
                  DataCell(
                    _FlashCell.num(
                      id: 'tusd-$id',
                      prev: prevSnap?.totalUsd,
                      value: usdOf(r),
                      fmt: AppFormatters.usd,
                      emphasize: true,
                    ),
                  ),
                  DataCell(
                    _FlashCell.num(
                      id: 'tbrl-$id',
                      prev: prevSnap?.totalBrl,
                      value: brlOf(r),
                      fmt: AppFormatters.brl,
                      emphasize: true,
                    ),
                  ),

                  DataCell(
                    _FlashCell.lock(
                      id: 'cbot-$id',
                      prevPct: prevSnap?.cbotPct,
                      ui: uiC,
                    ),
                  ),
                  DataCell(
                    _FlashCell.lock(
                      id: 'prem-$id',
                      prevPct: prevSnap?.premPct,
                      ui: uiP,
                    ),
                  ),
                  DataCell(
                    _FlashCell.lock(
                      id: 'fx-$id',
                      prevPct: prevSnap?.fxPct,
                      ui: uiF,
                    ),
                  ),

                  DataCell(ActionsMenu(onSelected: (a) => onAction(r, a))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ---------------- COMPACT LIST ----------------

class _CompactList extends StatelessWidget {
  final List<ContractMtmRow> rows;
  final DateFormat df;

  final LockStatusUi Function(ContractMtmRow r) cbotUi;
  final LockStatusUi Function(ContractMtmRow r) premUi;
  final LockStatusUi Function(ContractMtmRow r) fxUi;

  final double Function(ContractMtmRow r) brlOf;
  final double Function(ContractMtmRow r) usdOf;

  final OnContractAction onAction;

  final Map<int, _RowSnapshot> prev;
  final void Function(int id, _RowSnapshot next) commit;
  final _RowSnapshot Function(ContractMtmRow r) snapOf;

  const _CompactList({
    required this.rows,
    required this.df,
    required this.cbotUi,
    required this.premUi,
    required this.fxUi,
    required this.brlOf,
    required this.usdOf,
    required this.onAction,
    required this.prev,
    required this.commit,
    required this.snapOf,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          _ContractTile(
            row: rows[i],
            df: df,
            cbot: cbotUi(rows[i]),
            prem: premUi(rows[i]),
            fx: fxUi(rows[i]),
            totalUsd: usdOf(rows[i]),
            totalBrl: brlOf(rows[i]),
            onAction: onAction,
            prevSnap: prev[rows[i].contract.id],
            onCommit: (snap) => commit(rows[i].contract.id, snap),
            snapOf: snapOf,
          ),
          if (i != rows.length - 1)
            Divider(
              height: 18,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.55),
            ),
        ],
      ],
    );
  }
}

class _ContractTile extends StatelessWidget {
  final ContractMtmRow row;
  final DateFormat df;

  final LockStatusUi cbot;
  final LockStatusUi prem;
  final LockStatusUi fx;

  final double totalUsd;
  final double totalBrl;

  final OnContractAction onAction;

  final _RowSnapshot? prevSnap;
  final ValueChanged<_RowSnapshot> onCommit;
  final _RowSnapshot Function(ContractMtmRow r) snapOf;

  const _ContractTile({
    required this.row,
    required this.df,
    required this.cbot,
    required this.prem,
    required this.fx,
    required this.totalUsd,
    required this.totalBrl,
    required this.onAction,
    required this.prevSnap,
    required this.onCommit,
    required this.snapOf,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final c = row.contract;
    final id = c.id;

    final usdSaca = row.valuation.usdPerSaca.manual ?? row.valuation.usdPerSaca.system;
    final brlSaca = row.valuation.brlPerSaca.manual ?? row.valuation.brlPerSaca.system;

    final nextSnap = snapOf(row);
    WidgetsBinding.instance.addPostFrameCallback((_) => onCommit(nextSnap));

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onAction(row, 'detalhar'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contrato #$id',
                    style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  df.format(c.dataEntrega),
                  style: t.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                ActionsMenu(onSelected: (a) => onAction(row, a)),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(label: 'Volume', value: '${AppFormatters.ton(row.totals.tonTotal, decimals: 0)} t', id: 'vol-$id'),
                _MiniPill(label: 'Sacas', value: '${AppFormatters.sacas(row.totals.sacasTotal)} sc', id: 'sac-$id'),
                _MiniPill(label: 'USD/sc', value: AppFormatters.usd(usdSaca), id: 'usdsc-$id', prevNum: prevSnap?.usdSaca, num: (usdSaca ?? 0.0), fmt: AppFormatters.usd),
                _MiniPill(label: 'BRL/sc', value: AppFormatters.brl(brlSaca), id: 'brlsc-$id', prevNum: prevSnap?.brlSaca, num: (brlSaca ?? 0.0), fmt: AppFormatters.brl),
              ],
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(label: 'Total USD', value: AppFormatters.usd(totalUsd), id: 'tusd-$id', prevNum: prevSnap?.totalUsd, num: totalUsd, fmt: AppFormatters.usd),
                _MiniPill(label: 'Total BRL', value: AppFormatters.brl(totalBrl), id: 'tbrl-$id', prevNum: prevSnap?.totalBrl, num: totalBrl, fmt: AppFormatters.brl),
              ],
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _FlashCell.lock(id: 'cbot-$id', prevPct: prevSnap?.cbotPct, ui: cbot),
                _FlashCell.lock(id: 'prem-$id', prevPct: prevSnap?.premPct, ui: prem),
                _FlashCell.lock(id: 'fx-$id', prevPct: prevSnap?.fxPct, ui: fx),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- FLASH CELL ----------------

class _FlashCell extends StatefulWidget {
  final String id;
  final String text;
  final String? prevText;

  final double? value;
  final double? prevValue;
  final String Function(double v) fmt;

  final LockStatusUi? ui;
  final double? prevPct;

  final bool emphasize;

  const _FlashCell._({
    required this.id,
    required this.text,
    required this.prevText,
    required this.value,
    required this.prevValue,
    required this.fmt,
    required this.ui,
    required this.prevPct,
    required this.emphasize,
  });

  factory _FlashCell.text({
    required String id,
    required String text,
    String? prevText,
  }) {
    return _FlashCell._(
      id: id,
      text: text,
      prevText: prevText,
      value: null,
      prevValue: null,
      fmt: (v) => v.toString(),
      ui: null,
      prevPct: null,
      emphasize: false,
    );
  }

  factory _FlashCell.num({
    required String id,
    required double? prev,
    required double value,
    required String Function(double v) fmt,
    bool emphasize = false,
  }) {
    return _FlashCell._(
      id: id,
      text: fmt(value.isFinite ? value : 0.0),
      prevText: null,
      value: value.isFinite ? value : 0.0,
      prevValue: prev?.isFinite == true ? prev : null,
      fmt: fmt,
      ui: null,
      prevPct: null,
      emphasize: emphasize,
    );
  }

  factory _FlashCell.lock({
    required String id,
    required double? prevPct,
    required LockStatusUi ui,
  }) {
    return _FlashCell._(
      id: id,
      text: '${ui.label} ${AppFormatters.pct(ui.coveragePct, decimals: 0)}',
      prevText: null,
      value: ui.coveragePct.isFinite ? ui.coveragePct : 0.0,
      prevValue: prevPct?.isFinite == true ? prevPct : null,
      fmt: (v) => AppFormatters.pct(v, decimals: 0),
      ui: ui,
      prevPct: prevPct,
      emphasize: false,
    );
  }

  @override
  State<_FlashCell> createState() => _FlashCellState();
}

class _FlashCellState extends State<_FlashCell> {
  Color _flash = Colors.transparent;
  int _nonce = 0;

  bool _changed(double? a, double b) {
    if (a == null) return false; // primeiro build não pisca
    return (a - b).abs() > 0.00001;
  }

  @override
  void didUpdateWidget(covariant _FlashCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    // TEXT cell (volume)
    if (widget.value == null && widget.ui == null) {
      final prev = widget.prevText;
      if (prev != null && prev != widget.text) {
        _triggerFlash(wentUp: null);
      }
      return;
    }

    // NUM / LOCK cell
    final v = widget.value ?? 0.0;
    final prev = widget.prevValue;

    if (_changed(prev, v)) {
      final wentUp = prev == null ? null : (v > prev);
      _triggerFlash(wentUp: wentUp);
    }
  }

  Future<void> _triggerFlash({required bool? wentUp}) async {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;

    final flash = wentUp == null
        ? cs.secondary.withValues(alpha: 0.18)
        : (wentUp
            ? Colors.green.withValues(alpha: 0.18)
            : Colors.red.withValues(alpha: 0.18));

    final cur = ++_nonce;
    setState(() => _flash = flash);

    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    if (cur != _nonce) return;
    setState(() => _flash = Colors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final baseStyle = t.textTheme.bodyMedium?.copyWith(
      fontWeight: widget.emphasize ? FontWeight.w900 : FontWeight.w700,
      color: cs.onSurface.withValues(alpha: widget.emphasize ? 0.90 : 0.86),
    );

    // LOCK pill renderizado como antes (mas com flash no container)
    if (widget.ui != null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Color.alphaBlend(_flash, cs.surface),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_lockIcon(widget.ui!), size: 16, color: _lockTone(cs, widget.ui!).withValues(alpha: 0.92)),
            const SizedBox(width: 8),
            _AnimatedSwapText(
              text: widget.text,
              style: t.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      );
    }

    // normal cell
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _flash,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _AnimatedSwapText(
        text: widget.text,
        style: baseStyle,
      ),
    );
  }

  IconData _lockIcon(LockStatusUi ui) {
    switch (ui.state) {
      case LockVisualState.locked:
        return Icons.lock_rounded;
      case LockVisualState.partial:
        return Icons.lock_clock_rounded;
      case LockVisualState.open:
        return Icons.lock_open_rounded;
    }
  }

  Color _lockTone(ColorScheme cs, LockStatusUi ui) {
    switch (ui.state) {
      case LockVisualState.locked:
        return cs.primary;
      case LockVisualState.partial:
        return cs.secondary;
      case LockVisualState.open:
        return cs.tertiary;
    }
  }
}

class _AnimatedSwapText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _AnimatedSwapText({
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(anim);
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

// ---------------- UI HELPERS ----------------

class _ControlsRow extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool showOnlyOpen;
  final ValueChanged<bool> onToggleOpen;
  final VoidCallback onClear;

  const _ControlsRow({
    required this.searchCtrl,
    required this.showOnlyOpen,
    required this.onToggleOpen,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Buscar por #id ou entrega...',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      onPressed: onClear,
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
            onChanged: (_) => (context as Element).markNeedsBuild(),
          ),
        ),
        const SizedBox(width: 10),
        FilterChip(
          selected: showOnlyOpen,
          label: const Text('Somente abertos'),
          onSelected: onToggleOpen,
          selectedColor: cs.primary.withValues(alpha: 0.14),
          checkmarkColor: cs.primary.withValues(alpha: 0.90),
        ),
      ],
    );
  }
}

class LockPill extends StatelessWidget {
  final LockStatusUi ui;
  const LockPill({super.key, required this.ui});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    IconData icon;
    Color tone;

    switch (ui.state) {
      case LockVisualState.locked:
        icon = Icons.lock_rounded;
        tone = cs.primary;
        break;
      case LockVisualState.partial:
        icon = Icons.lock_clock_rounded;
        tone = cs.secondary;
        break;
      case LockVisualState.open:
        icon = Icons.lock_open_rounded;
        tone = cs.tertiary;
        break;
    }

    final bg = tone.withValues(alpha: 0.14);
    final bd = tone.withValues(alpha: 0.30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(bg, cs.surface),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tone.withValues(alpha: 0.92)),
          const SizedBox(width: 8),
          Text(
            '${ui.label} ${AppFormatters.pct(ui.coveragePct, decimals: 0)}',
            style: t.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionsMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const ActionsMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Ações',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'detalhar', child: Text('Detalhar')),
        PopupMenuItem(value: 'comparar', child: Text('Comparar Manual vs System')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'travar_cbot', child: Text('Travar CBOT…')),
        PopupMenuItem(value: 'travar_premio', child: Text('Travar Prêmio…')),
        PopupMenuItem(value: 'travar_fx', child: Text('Travar FX…')),
      ],
      child: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.86)),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String text;
  const _SummaryPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurfaceVariant.withValues(alpha: 0.92),
            ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;

  // para flash no compact
  final String id;
  final double? prevNum;
  final double? num;
  final String Function(double v)? fmt;

  const _MiniPill({
    required this.label,
    required this.value,
    required this.id,
    this.prevNum,
    this.num,
    this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final content = (num != null && fmt != null)
        ? _FlashCell.num(id: id, prev: prevNum, value: num!, fmt: fmt!)
        : _AnimatedSwapText(text: value, style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: t.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant.withValues(alpha: 0.92),
            ),
          ),
          Flexible(child: content),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: t.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- SNAPSHOT MODEL ----------------

class _RowSnapshot {
  final double ton;
  final double sacas;
  final double usdSaca;
  final double brlSaca;
  final double totalUsd;
  final double totalBrl;
  final double cbotPct;
  final double premPct;
  final double fxPct;

  const _RowSnapshot({
    required this.ton,
    required this.sacas,
    required this.usdSaca,
    required this.brlSaca,
    required this.totalUsd,
    required this.totalBrl,
    required this.cbotPct,
    required this.premPct,
    required this.fxPct,
  });
}
