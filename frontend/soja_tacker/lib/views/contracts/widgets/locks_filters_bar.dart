// lib/views/contracts_mtm_dashboard/widgets/locks_filters_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart';

class LocksFiltersBar extends StatefulWidget {
  final int farmId;
  final bool autoApply;
  final bool initiallyCollapsed;

  const LocksFiltersBar({
    super.key,
    required this.farmId,
    this.autoApply = false,
    this.initiallyCollapsed = true,
  });

  @override
  State<LocksFiltersBar> createState() => _LocksFiltersBarState();
}

class _LocksFiltersBarState extends State<LocksFiltersBar> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContractsMtmDashboardVM>(
      builder: (_, vm, __) {
        final t = Theme.of(context);
        final cs = t.colorScheme;
        final border = cs.outlineVariant.withValues(alpha: 0.55);

        final hasTypes = vm.lockTypes.isNotEmpty;
        final hasStates = vm.lockStates.isNotEmpty;
        final readyToApplyLocks = hasTypes && hasStates;

        final isActive = vm.noLocks || hasTypes || hasStates;
        final activeCount = (vm.noLocks ? 1 : 0) + vm.lockTypes.length + vm.lockStates.length;

        String summary() {
          if (vm.noLocks) return 'Sem travas (FIXO_BRL)';
          String typesLabel() {
            if (vm.lockTypes.isEmpty) return 'Tipos: —';
            final map = {'cbot': 'CBOT', 'premium': 'Prêmio', 'fx': 'FX'};
            final names = vm.lockTypes.map((e) => map[e] ?? e).toList();
            return 'Tipos: ${names.join(', ')}';
          }

          String statesLabel() {
            if (vm.lockStates.isEmpty) return 'Estados: —';
            final map = {'locked': 'Travado', 'open': 'Aberto'};
            final names = vm.lockStates.map((e) => map[e] ?? e).toList();
            return 'Estados: ${names.join(', ')}';
          }

          return '${typesLabel()} • ${statesLabel()}';
        }

        Future<void> apply({bool silent = true}) async {
          await vm.load(farmId: widget.farmId, silent: silent);
        }

        Widget badgeCount() {
          if (!isActive) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Text(
              '$activeCount',
              style: t.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.primary,
              ),
            ),
          );
        }

        FilterChip compactChip({
          required bool selected,
          required VoidCallback? onTap,
          required String label,
          required IconData icon,
        }) {
          return FilterChip(
            selected: selected,
            onSelected: onTap == null ? null : (_) => onTap(),
            label: Text(label),
            avatar: Icon(icon, size: 16),
            showCheckmark: true,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          );
        }

        Widget section({
          required String label,
          required String meta,
          required Widget child,
        }) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
              color: cs.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          );
        }

        Future<void> onNoLocksTap() async {
          vm.setNoLocks(!vm.noLocks);

          if (widget.autoApply) {
            await apply(silent: true);
          } else {
            vm.notifyUi();
          }
        }

        Future<void> onTypeTap(String id) async {
          vm.toggleLockType(id);

          if (widget.autoApply) {
            final nowReady = vm.lockTypes.isNotEmpty && vm.lockStates.isNotEmpty;
            if (nowReady) {
              await apply(silent: true);
              return;
            }
          }
          vm.notifyUi();
        }

        Future<void> onStateTap(String id) async {
          vm.toggleLockState(id);

          if (widget.autoApply) {
            final nowReady = vm.lockTypes.isNotEmpty && vm.lockStates.isNotEmpty;
            if (nowReady) {
              await apply(silent: true);
              return;
            }
          }
          vm.notifyUi();
        }

        final header = InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _collapsed = !_collapsed),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
              color: cs.surface,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.50),
                    border: Border.all(color: border),
                  ),
                  child: Icon(Icons.tune_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.85)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Filtros', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          badgeCount(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _collapsed ? (isActive ? summary() : 'Toque para configurar') : 'Configure e aplique',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive) ...[
                  IconButton(
                    tooltip: 'Limpar',
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: vm.loading
                        ? null
                        : () async {
                            vm.clearAllFilters();
                            await apply(silent: true);
                          },
                    icon: const Icon(Icons.clear_rounded),
                  ),
                ],
                IconButton(
                  tooltip: _collapsed ? 'Expandir' : 'Recolher',
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _collapsed ? 0.0 : 0.5,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ),
              ],
            ),
          ),
        );

        final body = LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 920;

            final noLocksSection = section(
              label: 'Modo',
              meta: vm.noLocks ? 'Somente contratos sem trava' : 'Filtrar por travas',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  compactChip(
                    selected: vm.noLocks,
                    onTap: vm.loading ? null : onNoLocksTap,
                    label: 'Sem travas (FIXO_BRL)',
                    icon: Icons.payments_rounded,
                  ),
                  if (!vm.noLocks)
                    Text(
                      'Ative para ver apenas contratos com preço em BRL já definido.',
                      style: t.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );

            final types = section(
              label: 'Tipos',
              meta: vm.noLocks
                  ? 'Desativado (Sem travas)'
                  : (vm.lockTypes.isEmpty ? 'Nenhum selecionado' : '${vm.lockTypes.length} selecionado(s)'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  compactChip(
                    selected: vm.lockTypes.contains('cbot'),
                    onTap: (vm.noLocks || vm.loading) ? null : () => onTypeTap('cbot'),
                    label: 'CBOT',
                    icon: Icons.ssid_chart_rounded,
                  ),
                  compactChip(
                    selected: vm.lockTypes.contains('premium'),
                    onTap: (vm.noLocks || vm.loading) ? null : () => onTypeTap('premium'),
                    label: 'Prêmio',
                    icon: Icons.stacked_line_chart_rounded,
                  ),
                  compactChip(
                    selected: vm.lockTypes.contains('fx'),
                    onTap: (vm.noLocks || vm.loading) ? null : () => onTypeTap('fx'),
                    label: 'FX',
                    icon: Icons.currency_exchange_rounded,
                  ),
                ],
              ),
            );

            final states = section(
              label: 'Estados',
              meta: vm.noLocks
                  ? 'Desativado (Sem travas)'
                  : (vm.lockStates.isEmpty ? 'Nenhum selecionado' : '${vm.lockStates.length} selecionado(s)'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  compactChip(
                    selected: vm.lockStates.contains('locked'),
                    onTap: (vm.noLocks || vm.loading) ? null : () => onStateTap('locked'),
                    label: 'Travado',
                    icon: Icons.lock_rounded,
                  ),
                  compactChip(
                    selected: vm.lockStates.contains('open'),
                    onTap: (vm.noLocks || vm.loading) ? null : () => onStateTap('open'),
                    label: 'Aberto',
                    icon: Icons.lock_open_rounded,
                  ),
                ],
              ),
            );

            final readyToApply = vm.noLocks || readyToApplyLocks;

            final actions = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
              ),
              child: Row(
                children: [
                  Icon(
                    readyToApply ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 18,
                    color: readyToApply ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.noLocks
                          ? 'Pronto: Sem travas (FIXO_BRL).'
                          : (readyToApplyLocks ? 'Pronto para aplicar.' : 'Selecione 1 Tipo e 1 Estado.'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: vm.loading
                        ? null
                        : () async {
                            vm.clearAllFilters();
                            await apply(silent: true);
                          },
                    child: const Text('Limpar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (!readyToApply || vm.loading) ? null : () async => apply(silent: false),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            );

            if (isWide) {
              return Column(
                children: [
                  noLocksSection,
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: types),
                      const SizedBox(width: 10),
                      Expanded(child: states),
                    ],
                  ),
                  const SizedBox(height: 10),
                  actions,
                ],
              );
            }

            return Column(
              children: [
                noLocksSection,
                const SizedBox(height: 10),
                types,
                const SizedBox(height: 10),
                states,
                const SizedBox(height: 10),
                actions,
              ],
            );
          },
        );

        return Column(
          children: [
            header,
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _collapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: const SizedBox(height: 4),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: body,
              ),
            ),
          ],
        );
      },
    );
  }
}
