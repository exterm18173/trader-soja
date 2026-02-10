// lib/views/contracts_mtm_dashboard/widgets/value_distribution_card.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../data/models/contracts_mtm/contracts_mtm_response.dart';

class ValueDistributionCard extends StatefulWidget {
  final List<ContractMtmRow> rows;
  final double Function(ContractMtmRow row) brlOf;

  /// quantos itens mostrar antes de agrupar em "Outros"
  final int topN;

  /// opcional: passe vm.updateTick para sincronizar animações
  final int? updateTick;

  const ValueDistributionCard({
    super.key,
    required this.rows,
    required this.brlOf,
    this.topN = 8,
    this.updateTick,
  });

  @override
  State<ValueDistributionCard> createState() => _ValueDistributionCardState();
}

class _ValueDistributionCardState extends State<ValueDistributionCard> {
  // --- flash control ---
  double? _prevTotal;
  Color _flashColor = Colors.transparent;
  int _flashNonce = 0;

  double _safe(double v) => v.isFinite ? v : 0.0;

  @override
  void didUpdateWidget(covariant ValueDistributionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // recalcula total "novo" (mesma lógica do build)
    final newTotal = _calcTotal(widget.rows);

    bool changed(double? a, double b) {
      if (a == null) return true;
      return (a - b).abs() > 0.005; // tolerância p/ BRL (evita ruído)
    }

    if (changed(_prevTotal, newTotal)) {
      final wentUp = (_prevTotal == null) ? null : (newTotal > _prevTotal!);
      _prevTotal = newTotal;
      _triggerFlash(wentUp: wentUp);
    }
  }

  double _calcTotal(List<ContractMtmRow> rows) {
    double sum = 0;
    for (final r in rows) {
      sum += _safe(widget.brlOf(r));
    }
    return sum;
  }

  Future<void> _triggerFlash({required bool? wentUp}) async {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;

    final flash = wentUp == null
        ? cs.secondary.withValues(alpha: 0.16)
        : (wentUp
            ? Colors.green.withValues(alpha: 0.16)
            : Colors.red.withValues(alpha: 0.16));

    final current = ++_flashNonce;
    setState(() => _flashColor = flash);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (current != _flashNonce) return;
    setState(() => _flashColor = Colors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();

    final t = Theme.of(context);
    final cs = t.colorScheme;

    final border = cs.outlineVariant.withValues(alpha: 0.55);
    final df = DateFormat('dd/MM/yyyy');

    // monta lista com valores
    final items = widget.rows
        .map((r) => _Item(
              row: r,
              value: _safe(widget.brlOf(r)),
            ))
        .toList();

    // total e ordenação
    items.sort((a, b) => b.value.compareTo(a.value));
    final total = items.fold<double>(0.0, (p, e) => p + e.value);

    // inicializa prevTotal na primeira renderização
    _prevTotal ??= total;

    // Top N + Outros
    final shown = <_ShownItem>[];
    double others = 0.0;

    for (var i = 0; i < items.length; i++) {
      if (i < widget.topN) {
        final r = items[i].row;
        shown.add(
          _ShownItem(
            label: 'Contrato #${r.contract.id} • ${df.format(r.contract.dataEntrega)}',
            value: items[i].value,
            color: cs.primary,
          ),
        );
      } else {
        others += items[i].value;
      }
    }

    if (others > 0) {
      shown.add(
        _ShownItem(
          label: 'Outros (${items.length - math.min(items.length, widget.topN)})',
          value: others,
          color: cs.tertiary,
        ),
      );
    }

    final maxValue = shown.map((e) => e.value).fold<double>(0.0, (p, v) => math.max(p, v));
    final max = maxValue <= 0 ? 1.0 : maxValue;

    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _HeaderIcon(icon: Icons.stacked_bar_chart_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Distribuição do Valor Total (BRL)',
                          style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  _AnimatedSwapText(
                    text: 'Total: ${AppFormatters.brl(total)} • Itens: ${widget.rows.length}',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  for (int i = 0; i < shown.length; i++) ...[
                    _BarRow(
                      label: shown[i].label,
                      value: shown[i].value,
                      max: max,
                      total: total <= 0 ? 1 : total,
                      color: Color.alphaBlend(
                        shown[i].color.withValues(alpha: 0.85),
                        cs.surface,
                      ),
                      // ✅ chave estável p/ animar por item
                      rowKey: shown[i].label,
                    ),
                    if (i != shown.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            // ✅ overlay flash
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: _flashColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final double total;
  final Color color;
  final String rowKey;

  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.total,
    required this.color,
    required this.rowKey,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final pct = (max <= 0) ? 0.0 : (value / max).clamp(0.0, 1.0);
    final pctOfTotal = (total <= 0) ? 0.0 : (value / total).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (_, c) {
        final compact = c.maxWidth < 520;

        final valueText = AppFormatters.brl(value);
        final pctText = AppFormatters.pct(pctOfTotal, decimals: 0);

        final barBg = cs.surfaceContainerHighest.withValues(alpha: 0.60);
        final barBorder = cs.outlineVariant.withValues(alpha: 0.55);

        final bar = Tooltip(
          message: '$valueText • $pctText do total',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: barBg)),

                  // ✅ anima largura da barra
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: v,
                          child: Container(color: color.withValues(alpha: 0.95)),
                        );
                      },
                    ),
                  ),

                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: barBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final labelWidget = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.92),
            fontWeight: FontWeight.w700,
          ),
        );

        // ✅ valores animados
        final rightWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniTag(text: pctText),
            const SizedBox(width: 8),
            _AnimatedSwapText(
              text: valueText,
              style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 8),
              bar,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: rightWidget),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: labelWidget),
                const SizedBox(width: 12),
                rightWidget,
              ],
            ),
            const SizedBox(height: 8),
            bar,
          ],
        );
      },
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(opacity: fade, child: child);
      },
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      child: Icon(
        icon,
        size: 18,
        color: cs.onSurface.withValues(alpha: 0.86),
      ),
    );
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

class _Item {
  final ContractMtmRow row;
  final double value;
  _Item({required this.row, required this.value});
}

class _ShownItem {
  final String label;
  final double value;
  final Color color;
  _ShownItem({required this.label, required this.value, required this.color});
}
