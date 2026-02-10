// lib/views/contracts_mtm_dashboard/widgets/header_meta.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeaderMeta extends StatelessWidget {
  final int farmId;
  final DateTime asOf;
  final String mode;

  const HeaderMeta({
    super.key,
    required this.farmId,
    required this.asOf,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final dt = DateFormat('dd/MM/yyyy HH:mm').format(asOf.toLocal());

    final border = cs.outlineVariant.withValues(alpha: 0.45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final isNarrow = c.maxWidth < 520;

          return Row(
            children: [
              // Farm (discreto)
              Expanded(
                child: Text(
                  'Farm #$farmId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Meta (bem “quieto”)
              Flexible(
                flex: 2,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    _MiniTag(
                      icon: Icons.schedule_rounded,
                      text: dt,
                    ),
                    _MiniTag(
                      icon: Icons.tune_rounded,
                      text: isNarrow ? mode : mode.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniTag({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final border = cs.outlineVariant.withValues(alpha: 0.40);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.78),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant.withValues(alpha: 0.86),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
