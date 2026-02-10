// lib/views/contracts_mtm_dashboard/widgets/kpi_grid.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart';

class KpiGrid extends StatelessWidget {
  final ContractsMtmKpis kpis;
  final int updateTick; // ✅ vem do VM
  const KpiGrid({super.key, required this.kpis, required this.updateTick});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final width = c.maxWidth;

        final maxTileWidth = width >= 1200 ? 420.0 : 460.0;
        final ratio = width >= 1200 ? 2.55 : (width >= 700 ? 2.25 : 2.45);

        final cards = <Widget>[
          _KpiCard(
            title: 'Volume Total',
            valueNumber: kpis.tonTotal,
            valueText: '${AppFormatters.ton(kpis.tonTotal, decimals: 0)} t',
            subtitleText: '${AppFormatters.sacas(kpis.sacasTotal)} sacas',
            icon: Icons.inventory_2_rounded,
            accent: Colors.indigo,
            flashKey: 'tonTotal',
            updateTick: updateTick,
          ),
          _KpiCard(
            title: 'Valor Total (BRL)',
            valueNumber: kpis.brlTotal,
            valueText: AppFormatters.brl(kpis.brlTotal),
            subtitleText: '${AppFormatters.brl(kpis.avgBrlPerSaca)} / saca',
            icon: Icons.payments_rounded,
            accent: Colors.green,
            flashKey: 'brlTotal',
            updateTick: updateTick,
          ),
          _KpiCard(
            title: 'Valor Total (USD)',
            valueNumber: kpis.usdTotal,
            valueText: AppFormatters.usd(kpis.usdTotal),
            subtitleText: '${AppFormatters.usd(kpis.avgUsdPerSaca)} / saca',
            icon: Icons.attach_money_rounded,
            accent: Colors.teal,
            flashKey: 'usdTotal',
            updateTick: updateTick,
          ),
          _KpiCard(
            title: 'Exposição FX',
            valueNumber: kpis.fxUnlockedPct,
            valueText: '${AppFormatters.pct(kpis.fxUnlockedPct, decimals: 0)} Aberto',
            subtitleText: 'Travado: ${AppFormatters.pct(kpis.fxLockedPct, decimals: 0)}',
            icon: Icons.currency_exchange_rounded,
            accent: Colors.deepOrange,
            flashKey: 'fxUnlockedPct',
            updateTick: updateTick,
            footer: _FxBar(
              lockedPct: kpis.fxLockedPct,
              unlockedPct: kpis.fxUnlockedPct,
            ),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxTileWidth,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemBuilder: (_, i) => cards[i],
        );
      },
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String title;

  final double valueNumber; // ✅ pra comparar
  final String valueText;
  final String subtitleText;

  final IconData icon;
  final Color accent;
  final Widget? footer;

  final String flashKey; // id estável
  final int updateTick; // muda quando VM atualizar

  const _KpiCard({
    required this.title,
    required this.valueNumber,
    required this.valueText,
    required this.subtitleText,
    required this.icon,
    required this.accent,
    required this.flashKey,
    required this.updateTick,
    this.footer,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hover = false;
  bool _pressed = false;

  double? _prev;
  Color _flashColor = Colors.transparent;

  // controla “voltar ao normal”
  int _flashNonce = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.valueNumber;
  }

  @override
  void didUpdateWidget(covariant _KpiCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ detecta mudança real do número
    final oldVal = _prev;
    final newVal = widget.valueNumber;

    // tolerância (evita piscar com micro-ruído)
    bool changed(double? a, double b) {
      if (a == null) return true;
      return (a - b).abs() > 0.00001;
    }

    if (changed(oldVal, newVal)) {
      final wentUp = (oldVal == null) ? null : (newVal > oldVal);

      _prev = newVal;
      _triggerFlash(wentUp: wentUp);
    }
  }

  void _triggerFlash({required bool? wentUp}) async {
    final cs = Theme.of(context).colorScheme;

    // você pediu “vermelho”: vou usar vermelho quando cai,
    // e verde quando sobe (fica bem intuitivo).
    final flash = wentUp == null
        ? cs.secondary.withValues(alpha: 0.18)
        : (wentUp
            ? Colors.green.withValues(alpha: 0.18)
            : Colors.red.withValues(alpha: 0.18));

    final current = ++_flashNonce;

    setState(() => _flashColor = flash);

    // volta ao normal
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
    final shadowColor = Colors.black.withValues(alpha: 0.10);

    final elevated = !_pressed && _hover;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, elevated ? -1.0 : 0.0, 0),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: !elevated
                ? const []
                : [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    )
                  ],
          ),
          child: Stack(
            children: [
              // conteúdo normal
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _AccentIcon(icon: widget.icon, accent: widget.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.labelLarge?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Flexible(
                            child: _AnimatedSwapText(
                              text: widget.valueText,
                              style: t.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            widget.subtitleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.90),
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          if (widget.footer != null) ...[
                            const SizedBox(height: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: widget.footer!,
                              ),
                            ),
                          ] else ...[
                            const Spacer(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ overlay do flash (animado)
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
      ),
    );
  }
}


class _AccentIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _AccentIcon({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = Color.alphaBlend(
      accent.withValues(alpha: 0.16),
      cs.surface,
    );

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: bg,
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Icon(
        icon,
        color: accent.withValues(alpha: 0.95),
        size: 22,
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
      child: FittedBox(
        key: ValueKey(text),
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}

/// FX bar “auto-adaptável”: se não tiver altura, esconde legendas
class _FxBar extends StatelessWidget {
  final double lockedPct; // 0..1
  final double unlockedPct; // 0..1

  const _FxBar({
    required this.lockedPct,
    required this.unlockedPct,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    double clamp01(double v) => v.isNaN ? 0 : v.clamp(0.0, 1.0);

    final locked = clamp01(lockedPct);
    final unlocked = clamp01(unlockedPct);

    final sum = locked + unlocked;
    final a = sum > 0 ? (locked / sum) : 0.0;
    final b = sum > 0 ? (unlocked / sum) : 0.0;

    final lockedColor = cs.primary.withValues(alpha: 0.88);
    final unlockedColor = cs.tertiary.withValues(alpha: 0.88);

    return LayoutBuilder(
      builder: (context, c) {
        const barH = 10.0;
        const gap = 8.0;
        const legendH = 16.0;

        final h = c.maxHeight;

        final canShowLegends = h >= (barH + gap + legendH);
        final canShowGap = h >= (barH + gap);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: barH,
                child: Row(
                  children: [
                    Expanded(
                      flex: math.max(1, (a * 1000).round()),
                      child: Container(color: lockedColor),
                    ),
                    Expanded(
                      flex: math.max(1, (b * 1000).round()),
                      child: Container(color: unlockedColor),
                    ),
                  ],
                ),
              ),
            ),
            if (canShowGap) SizedBox(height: canShowLegends ? gap : 4),
            if (canShowLegends)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(label: 'Travado', color: lockedColor),
                  const SizedBox(width: 10),
                  _LegendDot(label: 'Aberto', color: unlockedColor),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: t.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.90),
            fontWeight: FontWeight.w700,
          ),
        )
      ],
    );
  }
}


