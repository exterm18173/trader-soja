// lib/views/contracts_mtm_dashboard/contracts_mtm_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart';
import '../../data/models/contracts_mtm/contracts_mtm_response.dart';

import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_retry_widget.dart';

import 'widgets/header_meta.dart';
import 'widgets/locks_filters_bar.dart';
import 'widgets/view_side_toggle.dart';
import 'widgets/kpi_grid.dart';
import 'widgets/value_distribution_card.dart';
import 'widgets/fx_exposure_donut_card.dart';
import 'widgets/locks_breakdown_card.dart';
import 'widgets/contracts_table.dart';

class ContractsMtmDashboardScreen extends StatefulWidget {
  final int farmId;
  const ContractsMtmDashboardScreen({super.key, required this.farmId});

  @override
  State<ContractsMtmDashboardScreen> createState() =>
      _ContractsMtmDashboardScreenState();
}

class _ContractsMtmDashboardScreenState
    extends State<ContractsMtmDashboardScreen> {
  final _leftCarousel = PageController(viewportFraction: 1.0);
  int _leftIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<ContractsMtmDashboardVM>();

      vm.load(farmId: widget.farmId);

      // ✅ Realtime automático (ajuste o intervalo aqui)
      vm.startRealtime(
        farmId: widget.farmId,
        every: const Duration(seconds: 10),
      );
    });
  }

  @override
  void dispose() {
    _leftCarousel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContractsMtmDashboardVM>(
      builder: (_, vm, __) {
        if (vm.data == null) {
          if (vm.loading) {
            return const Scaffold(
              body: Center(
                child: LoadingWidget(message: 'Carregando dashboard...'),
              ),
            );
          }

          if (vm.error != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Dashboard de Contratos')),
              body: ErrorRetryWidget(
                title: 'Erro ao carregar',
                message: vm.errMsg(vm.error),
                onRetry: () => vm.load(farmId: widget.farmId),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard de Contratos')),
            body: Center(
              child: FilledButton.icon(
                onPressed: () => vm.load(farmId: widget.farmId),
                icon: const Icon(Icons.refresh),
                label: const Text('Carregar dados'),
              ),
            ),
          );
        }

        final ContractsMtmResponse data = vm.data!;
        final kpis = vm.kpis;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard de Contratos'),
            actions: [
              // ✅ status realtime
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: _RealtimeChip(
                    enabled: vm.realtimeEnabled,
                    onTap: () => vm.toggleRealtime(farmId: widget.farmId),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar agora',
                onPressed: vm.loading
                    ? null
                    : () => vm.load(farmId: widget.farmId),
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => vm.load(farmId: widget.farmId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vm.loading) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 12),
                ],

                HeaderMeta(
                  farmId: data.farmId,
                  asOf: data.asOfTs,
                  mode: data.mode,
                ),
                const SizedBox(height: 12),

                ViewSideToggle(value: vm.viewSide, onChanged: vm.setViewSide),
                const SizedBox(height: 12),

                LocksFiltersBar(
                  farmId: widget.farmId,
                  autoApply: false,
                  initiallyCollapsed: true,
                ),

                const SizedBox(height: 16),

                // ✅ passa “tick” para ajudar animações (opcional)
                KpiGrid(kpis: kpis, updateTick: vm.updateTick),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth >= 920;

                    final leftCards = <Widget>[
                      ValueDistributionCard(
                        rows: data.rows, // melhor!
                        brlOf: vm.brlOfRow,
                        topN: 8,
                        updateTick: vm.updateTick,
                      ),

                      LocksBreakdownCard(
                        title: 'Distribuição dos Travamentos (CBOT)',
                        breakdown: vm.breakdownForCbot(),
                        totalsUsd: kpis.usdTotal,
                        updateTick: vm.updateTick,
                      ),
                      LocksBreakdownCard(
                        title: 'Distribuição dos Travamentos (Prêmio)',
                        breakdown: vm.breakdownForPremium(),
                        totalsUsd: kpis.usdTotal,
                        updateTick: vm.updateTick,
                      ),
                      LocksBreakdownCard(
                        title: 'Distribuição dos Travamentos (FX)',
                        breakdown: vm.breakdownForFx(),
                        totalsUsd: kpis.usdTotal,
                        updateTick: vm.updateTick,
                      ),
                    ];

                    final left = _CardsCarousel(
                      title: 'Análises',
                      items: leftCards,
                      controller: _leftCarousel,
                      index: _leftIndex,
                      onIndexChanged: (i) => setState(() => _leftIndex = i),
                      labels: const [
                        'Distribuição BRL',
                        'Travamentos CBOT',
                        'Travamentos Prêmio',
                        'Travamentos FX',
                      ],
                    );

                    final right = FxExposureDonutCard(
                      lockedPct: kpis.fxLockedPct,
                      unlockedPct: kpis.fxUnlockedPct,
                      totalUsd: kpis.usdTotal,
                      updateTick: vm.updateTick, // opcional
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: left),
                          const SizedBox(width: 12),
                          Expanded(flex: 5, child: right),
                        ],
                      );
                    }

                    return Column(
                      children: [right, const SizedBox(height: 12), left],
                    );
                  },
                ),

                const SizedBox(height: 16),

                ContractsTable(
                  rows: data.rows,
                  cbotUi: vm.cbotUi,
                  premUi: vm.premiumUi,
                  fxUi: vm.fxUi,
                  brlOf: vm.brlOfRow,
                  usdOf: vm.usdOfRow,
                  viewSide: vm.viewSide,
                  initialSort: const TableSort(
                    column: ContractsSortColumn.totalBrl,
                    ascending: false,
                  ),
                  onAction: (row, action) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ação "$action" no contrato #${row.contract.id}',
                        ),
                      ),
                    );
                  },
                  updateTick: vm.updateTick,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RealtimeChip extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _RealtimeChip({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
          color: enabled
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled
                  ? Icons.wifi_tethering_rounded
                  : Icons.wifi_tethering_off_rounded,
              size: 16,
              color: enabled ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              enabled ? 'Realtime ON' : 'Realtime OFF',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: enabled ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carrossel de cards (um por vez) + controles (setas, dots, label)
class _CardsCarousel extends StatefulWidget {
  final String title;
  final List<Widget> items;
  final List<String> labels;

  final PageController controller;
  final int index;
  final ValueChanged<int> onIndexChanged;

  const _CardsCarousel({
    required this.title,
    required this.items,
    required this.labels,
    required this.controller,
    required this.index,
    required this.onIndexChanged,
  });

  @override
  State<_CardsCarousel> createState() => _CardsCarouselState();
}

class _CardsCarouselState extends State<_CardsCarousel> {
  double _currentHeight = 320; // fallback inicial

  void _updateHeight(double h) {
    // evita setState em loop e micro variações
    final nh = h.isFinite ? h : 320;
    if ((nh - _currentHeight).abs() < 2) return;
    setState(() => _currentHeight = nh.clamp(220, 900).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final border = cs.outlineVariant.withValues(alpha: 0.55);

    void go(int i) {
      if (widget.items.isEmpty) return;
      final target = i.clamp(0, widget.items.length - 1);
      widget.controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }

    final canPrev = widget.index > 0;
    final canNext = widget.index < widget.items.length - 1;

    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header do carrossel
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                    border: Border.all(color: border),
                  ),
                  child: Icon(
                    Icons.view_carousel_rounded,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: t.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.labels.isNotEmpty
                            ? widget.labels[widget.index.clamp(
                                0,
                                widget.labels.length - 1,
                              )]
                            : '—',
                        style: t.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Anterior',
                  onPressed: canPrev ? () => go(widget.index - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Próximo',
                  onPressed: canNext ? () => go(widget.index + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                _Dots(
                  count: widget.items.length,
                  activeIndex: widget.index,
                  onTap: go,
                ),
                const Spacer(),
                _MiniPill(text: '${widget.index + 1}/${widget.items.length}'),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ AQUI: PageView com altura controlada (resolve unbounded height)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _currentHeight,
                child: PageView.builder(
                  controller: widget.controller,
                  itemCount: widget.items.length,
                  onPageChanged: widget.onIndexChanged,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, i) {
                    return _MeasureSize(
                      onChange: _updateHeight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: widget.items[i],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mede a altura do child e devolve via callback.
/// Isso permite que o PageView tenha altura “auto” (animada).
class _MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onChange;

  const _MeasureSize({required this.child, required this.onChange});

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  final _key = GlobalKey();
  Size? _oldSize;

  @override
  void didUpdateWidget(covariant _MeasureSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
  }

  void _notifySize() {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final newSize = ctx.size;
    if (newSize == null) return;
    if (_oldSize == newSize) return;

    _oldSize = newSize;
    widget.onChange(newSize.height);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _Dots({
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = cs.outlineVariant.withValues(alpha: 0.55);

    return Wrap(
      spacing: 6,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        final w = active ? 18.0 : 10.0;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: w,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active
                  ? cs.primary.withValues(alpha: 0.75)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.65),
              border: Border.all(color: border),
            ),
          ),
        );
      }),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = cs.outlineVariant.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
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
