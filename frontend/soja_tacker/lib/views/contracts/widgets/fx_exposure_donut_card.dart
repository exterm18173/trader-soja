// lib/views/contracts_mtm_dashboard/widgets/fx_exposure_donut_card.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/formatters/app_formatters.dart';

class FxExposureDonutCard extends StatefulWidget {
  final double lockedPct;
  final double unlockedPct;
  final double totalUsd;

  // opcional: se você quiser forçar rebuild/flash em sync com o VM
  final int? updateTick;

  const FxExposureDonutCard({
    super.key,
    required this.lockedPct,
    required this.unlockedPct,
    required this.totalUsd,
    this.updateTick,
  });

  @override
  State<FxExposureDonutCard> createState() => _FxExposureDonutCardState();
}

class _FxExposureDonutCardState extends State<FxExposureDonutCard> {
  int? _touchedIndex;

  // --- flash control ---
  double? _prevUnlocked; // comparação (antes normalizar)
  Color _flashColor = Colors.transparent;
  int _flashNonce = 0;

  @override
  void initState() {
    super.initState();
    _prevUnlocked = _safe(widget.unlockedPct);
  }

  @override
  void didUpdateWidget(covariant FxExposureDonutCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldVal = _prevUnlocked;
    final newVal = _safe(widget.unlockedPct);

    // tolerância pra evitar ruído
    bool changed(double? a, double b) {
      if (a == null) return true;
      return (a - b).abs() > 0.00001;
    }

    if (changed(oldVal, newVal)) {
      final wentUp = (oldVal == null) ? null : (newVal > oldVal);
      _prevUnlocked = newVal;
      _triggerFlash(wentUp: wentUp);
    }
  }

  double _safe(double v) => v.isFinite ? v : 0.0;

  Future<void> _triggerFlash({required bool? wentUp}) async {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;

    final flash = wentUp == null
        ? cs.secondary.withValues(alpha: 0.18)
        : (wentUp
            ? Colors.green.withValues(alpha: 0.18)
            : Colors.red.withValues(alpha: 0.18));

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

    double l = _safe(widget.lockedPct);
    double u = _safe(widget.unlockedPct);

    final sumRaw = l + u;
    if (sumRaw > 0) {
      l = (l / sumRaw).clamp(0.0, 1.0);
      u = (u / sumRaw).clamp(0.0, 1.0);
    } else {
      l = 0.0;
      u = 0.0;
    }

    final totalUsd = _safe(widget.totalUsd);
    final hasData = (l + u) > 0;

    final lockedUsd = totalUsd * l;
    final unlockedUsd = totalUsd * u;

    final lockedColor = cs.primary.withValues(alpha: 0.90);
    final unlockedColor = cs.tertiary.withValues(alpha: 0.90);

    final border = cs.outlineVariant.withValues(alpha: 0.55);

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
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _HeaderIcon(icon: Icons.currency_exchange_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Exposição FX (USD)',
                          style: t.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (_, c) {
                      final w = c.maxWidth;
                      final donutSize = math.min(w, 280.0);
                      final donutH = math.max(180.0, donutSize);

                      if (!hasData) {
                        return Container(
                          height: donutH,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
                          ),
                          child: Text(
                            'Sem dados de exposição FX',
                            style: t.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }

                      final baseRadius = donutH * 0.30;
                      final centerSpaceRadius = donutH * 0.22;

                      final center = _touchedIndex == 0
                          ? _CenterLabel(
                              title: 'Travado',
                              pct: l,
                              usd: lockedUsd,
                              subtitle: 'Total: ${AppFormatters.usd(totalUsd)}',
                            )
                          : _touchedIndex == 1
                              ? _CenterLabel(
                                  title: 'Aberto',
                                  pct: u,
                                  usd: unlockedUsd,
                                  subtitle: 'Total: ${AppFormatters.usd(totalUsd)}',
                                )
                              : _CenterLabel(
                                  title: 'Aberto',
                                  pct: u,
                                  usd: unlockedUsd,
                                  subtitle: 'Toque no gráfico',
                                );

                      return SizedBox(
                        height: donutH,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                startDegreeOffset: -90,
                                sectionsSpace: 3,
                                centerSpaceRadius: centerSpaceRadius,
                                sections: _sections(
                                  context: context,
                                  locked: l,
                                  unlocked: u,
                                  lockedColor: lockedColor,
                                  unlockedColor: unlockedColor,
                                  touchedIndex: _touchedIndex,
                                  baseRadius: baseRadius,
                                ),
                                pieTouchData: PieTouchData(
                                  enabled: true,
                                  touchCallback: (event, resp) {
                                    final idx = resp?.touchedSection?.touchedSectionIndex;
                                    setState(() {
                                      if (!event.isInterestedForInteractions || idx == null) {
                                        _touchedIndex = null;
                                      } else {
                                        _touchedIndex = idx;
                                      }
                                    });
                                  },
                                ),
                              ),
                              swapAnimationDuration: const Duration(milliseconds: 250),
                              swapAnimationCurve: Curves.easeOutCubic,
                            ),

                            // Centro do donut
                            Container(
                              width: centerSpaceRadius * 2,
                              height: centerSpaceRadius * 2,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(alpha: 0.55),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: IgnorePointer(child: center),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // KPI principal (com troca suave)
                  _AnimatedSwapText(
                    text: '${AppFormatters.pct(u, decimals: 0)} Aberto',
                    style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),

                  // Linha resumo (com troca suave)
                  _AnimatedSwapText(
                    text:
                        'Total USD: ${AppFormatters.usd(totalUsd)} • Travado: ${AppFormatters.pct(l, decimals: 0)}',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _LegendPill(
                        color: unlockedColor,
                        label: 'Aberto',
                        pct: u,
                        usd: unlockedUsd,
                      ),
                      _LegendPill(
                        color: lockedColor,
                        label: 'Travado',
                        pct: l,
                        usd: lockedUsd,
                      ),
                    ],
                  ),
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

  List<PieChartSectionData> _sections({
    required BuildContext context,
    required double locked,
    required double unlocked,
    required Color lockedColor,
    required Color unlockedColor,
    required int? touchedIndex,
    required double baseRadius,
  }) {
    final cs = Theme.of(context).colorScheme;

    PieChartSectionData sec({
      required double value,
      required Color color,
      required int index,
    }) {
      final isTouched = touchedIndex == index;
      final radius = isTouched ? (baseRadius + 8) : baseRadius;

      return PieChartSectionData(
        value: value * 100,
        title: '',
        color: color,
        radius: radius,
        borderSide: isTouched
            ? BorderSide(color: cs.onSurface.withValues(alpha: 0.12), width: 2)
            : BorderSide(color: cs.surface.withValues(alpha: 1.0), width: 1),
      );
    }

    return [
      sec(value: locked, color: lockedColor, index: 0),
      sec(value: unlocked, color: unlockedColor, index: 1),
    ];
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

class _CenterLabel extends StatelessWidget {
  final String title;
  final double pct; // 0..1
  final double usd;
  final String? subtitle;

  const _CenterLabel({
    required this.title,
    required this.pct,
    required this.usd,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: t.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.pct(pct, decimals: 0),
            style: t.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.usd(usd),
            style: t.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant.withValues(alpha: 0.92),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;
  final double pct; // 0..1
  final double usd;

  const _LegendPill({
    required this.color,
    required this.label,
    required this.pct,
    required this.usd,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 8),
          _AnimatedSwapText(
            text: '${AppFormatters.pct(pct, decimals: 0)} • ${AppFormatters.usd(usd)}',
            style: t.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.92),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mesmo AnimatedSwitcher que você já usa (pra evitar dependência do KPI file)
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
