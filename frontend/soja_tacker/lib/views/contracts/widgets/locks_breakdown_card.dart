// lib/views/contracts_mtm_dashboard/widgets/locks_breakdown_card.dart

import 'package:flutter/material.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart';

class LocksBreakdownCard extends StatefulWidget {
  final String title;
  final LockBreakdown breakdown;
  final double totalsUsd;

  /// opcional: passe vm.updateTick para sincronizar
  final int? updateTick;

  const LocksBreakdownCard({
    super.key,
    required this.title,
    required this.breakdown,
    required this.totalsUsd,
    this.updateTick,
  });

  @override
  State<LocksBreakdownCard> createState() => _LocksBreakdownCardState();
}

class _LocksBreakdownCardState extends State<LocksBreakdownCard> {
  // --- flash control ---
  double? _prevSumUsd;
  Color _flashColor = Colors.transparent;
  int _flashNonce = 0;

  double _safe(double v) => v.isFinite ? v : 0.0;

  double _sumUsd(LockBreakdown b) => _safe(b.locked.usd) + _safe(b.open.usd);

  @override
  void initState() {
    super.initState();
    _prevSumUsd = _sumUsd(widget.breakdown);
  }

  @override
  void didUpdateWidget(covariant LocksBreakdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newSum = _sumUsd(widget.breakdown);

    bool changed(double? a, double b) {
      if (a == null) return true;
      // tolerância: evita piscar com variações minúsculas
      return (a - b).abs() > 0.01;
    }

    if (changed(_prevSumUsd, newSum)) {
      final wentUp = (_prevSumUsd == null) ? null : (newSum > _prevSumUsd!);
      _prevSumUsd = newSum;
      _triggerFlash(wentUp: wentUp);
    }
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
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final border = cs.outlineVariant.withValues(alpha: 0.55);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header compacto
        Row(
          children: [
            const _HeaderIcon(icon: Icons.lock_outline_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _LineRowAdaptive(
          label: 'Travado',
          a: widget.breakdown.locked,
          totalsUsd: widget.totalsUsd,
          tone: cs.primary.withValues(alpha: 0.90),
        ),
        const SizedBox(height: 8),
        _LineRowAdaptive(
          label: 'Aberto',
          a: widget.breakdown.open,
          totalsUsd: widget.totalsUsd,
          tone: cs.tertiary.withValues(alpha: 0.90),
        ),
      ],
    );

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
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (_, c) {
                  // ✅ Quando o pai (PageView) limita altura, ocupa o máximo e faz scroll interno.
                  if (c.maxHeight.isFinite) {
                    return SizedBox(
                      height: c.maxHeight,
                      child: ClipRect(
                        child: SingleChildScrollView(
                          primary: false,
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: c.maxHeight),
                            child: content,
                          ),
                        ),
                      ),
                    );
                  }
                  return content;
                },
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

class _LineRowAdaptive extends StatelessWidget {
  final String label;
  final LockAggregates a;
  final double totalsUsd;
  final Color tone;

  const _LineRowAdaptive({
    required this.label,
    required this.a,
    required this.totalsUsd,
    required this.tone,
  });

  double _safe(double v) => v.isFinite ? v : 0.0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final usdN = _safe(a.usd);
    final brlN = _safe(a.brl);
    final tonN = _safe(a.ton);
    final sacN = _safe(a.sacas);

    final totUsd = totalsUsd.isFinite ? totalsUsd : 0.0;
    final pct = (totUsd <= 0) ? 0.0 : (usdN / totUsd).clamp(0.0, 1.0);
    final pctText = AppFormatters.pct(pct, decimals: 0);

    final bg = cs.surfaceContainerHighest.withValues(alpha: 0.26);
    final border = cs.outlineVariant.withValues(alpha: 0.55);

    final usd = AppFormatters.usd(usdN);
    final brl = AppFormatters.brl(brlN);
    final ton = AppFormatters.ton(tonN, decimals: 0);
    final sc = AppFormatters.sacas(sacN);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth;

          final pill = AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.withValues(alpha: 0.28)),
            ),
            child: _AnimatedSwapText(
              text: pctText,
              style: t.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface.withValues(alpha: 0.88),
              ),
            ),
          );

          final header = Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface.withValues(alpha: 0.86),
                  ),
                ),
              ),
              pill,
            ],
          );

          // (opcional) micro bar de % — ajuda leitura sem “poluir”
          final miniBar = _MiniPctBar(pct: pct, tone: tone);

          // super compacto (texto em 2 linhas no máximo)
          if (w < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                miniBar,
                const SizedBox(height: 8),
                _AnimatedSwapText(
                  text: 'USD $usd • BRL $brl • $ton t • $sc sc',
                  style: t.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                  ),
                ),
              ],
            );
          }

          // médio (2 linhas)
          if (w < 560) {
            final s = t.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant.withValues(alpha: 0.92),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                miniBar,
                const SizedBox(height: 8),
                _AnimatedSwapText(
                  text: 'USD $usd • BRL $brl',
                  style: s,
                ),
                const SizedBox(height: 4),
                _AnimatedSwapText(
                  text: '$ton t • $sc sc',
                  style: s,
                ),
              ],
            );
          }

          // wide (chips pequenos)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 8),
              miniBar,
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TinyChip(text: 'USD $usd'),
                  _TinyChip(text: 'BRL $brl'),
                  _TinyChip(text: '$ton t'),
                  _TinyChip(text: '$sc sc'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniPctBar extends StatelessWidget {
  final double pct; // 0..1
  final Color tone;
  const _MiniPctBar({required this.pct, required this.tone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerHighest.withValues(alpha: 0.50);
    final border = cs.outlineVariant.withValues(alpha: 0.55);

    final p = pct.isFinite ? pct.clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: bg)),
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: p),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: Container(color: tone.withValues(alpha: 0.95)),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String text;
  const _TinyChip({required this.text});

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
          color: cs.surface.withValues(alpha: 1.0),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
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
      width: 34,
      height: 34,
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

  const _AnimatedSwapText({required this.text, required this.style});

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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
