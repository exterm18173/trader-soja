import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/farm_context.dart';
import '../../routes/app_routes.dart';

// Telas
import '../../views/rates/interest_rates_screen.dart';
import '../../views/rates/offsets_screen.dart';
import '../../views/expenses/expenses_usd_screen.dart';

import '../../views/fx/fx_spot_screen.dart';
import '../../views/fx/fx_quotes_screen.dart';
import '../../views/fx/fx_manual_points_screen.dart';
import '../../views/fx/fx_model_runs_screen.dart';

import '../../views/cbot/cbot_sources_screen.dart';
import '../../views/cbot/cbot_quotes_screen.dart';

import '../../views/contracts/contracts_screen.dart';
import '../../views/alerts/alert_rules_screen.dart';
import '../../views/alerts/alert_events_screen.dart';

import '../contracts/contracts_mtm_dashboard_screen.dart';
import '../contracts/contracts_mtm_screen.dart';
import '../dashboard/contracts_result_dashboard_screen.dart';

import '../fx/fx_futures_quotes_screen.dart';
import '../fx/fx_sources_screen.dart';
import '../hedges/hedges_screen.dart';

/// ----------------------------
/// MODELOS
/// ----------------------------

class ShellSection {
  final String label;
  final List<ShellItem> items;

  const ShellSection({required this.label, required this.items});
}

class ShellItem {
  final String label;
  final IconData icon;
  final Widget page;

  const ShellItem({
    required this.label,
    required this.icon,
    required this.page,
  });
}

/// ----------------------------
/// APP SHELL (COM TOGGLE DE MENU NO DESKTOP)
/// ----------------------------

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _sectionIndex = 0;
  int _itemIndex = 0;

  final _searchCtrl = TextEditingController();
  String _query = '';

  // estados de colapso por seção (desktop)
  late final List<bool> _expanded;

  // ✅ novo: permite ocultar/exibir a sidebar mesmo em telas grandes
  bool _sidebarOpen = true;

  void _toggleSidebar() => setState(() => _sidebarOpen = !_sidebarOpen);

  late final List<ShellSection> _sections = [
    ShellSection(
      label: 'Visão Geral',
      items: const [
        ShellItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          page: ContractsResultDashboardScreen(),
        ),
        ShellItem(
          label: 'Contratos',
          icon: Icons.description_outlined,
          page: ContractsMtmScreen(farmId: 3),
        ),
        ShellItem(
          label: 'Contratos MT',
          icon: Icons.table_chart_outlined,
          page: ContractsMtmDashboardScreen(farmId: 3),
        ),
      ],
    ),
    ShellSection(
      label: 'Rates & Custos',
      items: const [
        ShellItem(
          label: 'Juros',
          icon: Icons.percent,
          page: InterestRatesScreen(),
        ),
        ShellItem(
          label: 'Offsets',
          icon: Icons.tune,
          page: OffsetsScreen(),
        ),
        ShellItem(
          label: 'Despesas USD',
          icon: Icons.attach_money,
          page: ExpensesUsdScreen(),
        ),
      ],
    ),
    ShellSection(
      label: 'FX',
      items: const [
        ShellItem(
          label: 'Spot',
          icon: Icons.currency_exchange,
          page: FxSpotScreen(),
        ),
        ShellItem(
          label: 'Quotes',
          icon: Icons.show_chart,
          page: FxQuotesScreen(),
        ),
        ShellItem(
          label: 'Manual Points',
          icon: Icons.edit,
          page: FxManualPointsScreen(),
        ),
        ShellItem(
          label: 'Model Runs',
          icon: Icons.science,
          page: FxModelRunsScreen(),
        ),
        ShellItem(
          label: 'Fx Sources',
          icon: Icons.source_outlined,
          page: FxSourcesScreen(),
        ),
      ],
    ),
    ShellSection(
      label: 'HEDES',
      items: const [
        ShellItem(
          label: 'Hedges',
          icon: Icons.height_rounded,
          page: HedgesScreen(contractId: 3),
        ),
      ],
    ),
    ShellSection(
      label: 'CBOT',
      items: const [
        ShellItem(
          label: 'Sources',
          icon: Icons.source_outlined,
          page: CbotSourcesScreen(),
        ),
        ShellItem(
          label: 'Quotes',
          icon: Icons.trending_up,
          page: CbotQuotesScreen(),
        ),
      ],
    ),
    ShellSection(
      label: 'Contratos',
      items: const [
        ShellItem(
          label: 'Lista',
          icon: Icons.description_outlined,
          page: ContractsScreen(),
        ),
      ],
    ),
    ShellSection(
      label: 'Alertas',
      items: const [
        ShellItem(
          label: 'Regras',
          icon: Icons.notifications_outlined,
          page: AlertRulesScreen(),
        ),
        ShellItem(
          label: 'Eventos',
          icon: Icons.warning_amber_outlined,
          page: AlertEventsScreen(),
        ),
      ],
    ),
    ShellSection(
      label: 'novas',
      items: const [
        ShellItem(
          label: 'FX',
          icon: Icons.fax_outlined,
          page: FxFuturesQuotesScreen(farmId: 3),
        ),
      ],
    ),
  ];

  ShellItem get _current => _sections[_sectionIndex].items[_itemIndex];

  @override
  void initState() {
    super.initState();
    _expanded = List<bool>.filled(_sections.length, true);

    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectItem(int section, int item) {
    setState(() {
      _sectionIndex = section;
      _itemIndex = item;
    });
  }

  List<ShellItem> _flatItems() => _sections.expand((s) => s.items).toList();

  int _flatIndexFromSectionItem() {
    int acc = 0;
    for (int s = 0; s < _sections.length; s++) {
      for (int i = 0; i < _sections[s].items.length; i++) {
        if (s == _sectionIndex && i == _itemIndex) return acc;
        acc++;
      }
    }
    return 0;
  }

  void _selectFromFlatIndex(int flatIndex) {
    int acc = 0;
    for (int s = 0; s < _sections.length; s++) {
      for (int i = 0; i < _sections[s].items.length; i++) {
        if (acc == flatIndex) {
          _selectItem(s, i);
          return;
        }
        acc++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmCtx = context.watch<FarmContext>();

    /// 🔒 sem fazenda → volta para seleção
    if (!farmCtx.hasFarm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.farms);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width >= 1000;
    final current = _current;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: wide ? 8 : null,
        title: _TopBarTitle(
          section: _sections[_sectionIndex].label,
          page: current.label,
        ),
        actions: [
          if (wide) ...[
            IconButton(
              tooltip: _sidebarOpen ? 'Ocultar menu' : 'Mostrar menu',
              icon: Icon(_sidebarOpen ? Icons.menu_open : Icons.menu),
              onPressed: _toggleSidebar,
            ),
            const SizedBox(width: 8),
            _FarmChipCompact(farmId: farmCtx.farmId),
            const SizedBox(width: 8),
          ],
          if (!wide) ...[
            _FarmChipCompact(farmId: farmCtx.farmId),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: 'Trocar fazenda',
            icon: const Icon(Icons.agriculture),
            onPressed: () async {
              await farmCtx.clear();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.farms);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: cs.surface,
        child: LayoutBuilder(
          builder: (context, c) {
            if (!wide) {
              return _PageFade(child: current.page);
            }

            return Row(
              children: [
                _SidebarHost(
                  open: _sidebarOpen,
                  width: 312,
                  child: _Sidebar(
                    sections: _sections,
                    sectionIndex: _sectionIndex,
                    itemIndex: _itemIndex,
                    expanded: _expanded,
                    query: _query,
                    searchCtrl: _searchCtrl,
                    onToggleSection: (s) {
                      setState(() => _expanded[s] = !_expanded[s]);
                    },
                    onTap: _selectItem,
                    farmId: farmCtx.farmId,
                    onClearSearch: () => _searchCtrl.clear(),
                  ),
                ),
                if (_sidebarOpen)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: cs.outlineVariant,
                  ),
                Expanded(
                  child: Container(
                    color: cs.surface,
                    child: _PageFade(child: current.page),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: wide
          ? const SizedBox.shrink()
          : NavigationBar(
              selectedIndex: _flatIndexFromSectionItem(),
              onDestinationSelected: _selectFromFlatIndex,
              destinations: [
                for (final it in _flatItems())
                  NavigationDestination(icon: Icon(it.icon), label: it.label),
              ],
            ),
    );
  }
}

/// ----------------------------
/// TOP BAR TITLE (BREADCRUMB)
/// ----------------------------

class _TopBarTitle extends StatelessWidget {
  final String section;
  final String page;

  const _TopBarTitle({required this.section, required this.page});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(section, style: t.titleMedium),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            page,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// ----------------------------
/// FARM CHIP (COMPACT)
/// ----------------------------

class _FarmChipCompact extends StatelessWidget {
  final int? farmId;
  const _FarmChipCompact({required this.farmId});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.agriculture, size: 18),
      label: Text('Fazenda #$farmId'),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// ----------------------------
/// PAGE TRANSITION (FADE)
/// ----------------------------

class _PageFade extends StatelessWidget {
  final Widget child;
  const _PageFade({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
    );
  }
}

/// ----------------------------
/// SIDEBAR HOST (ANIMAÇÃO ABRIR/FECHAR)
/// ----------------------------

class _SidebarHost extends StatelessWidget {
  final bool open;
  final double width;
  final Widget child;

  const _SidebarHost({
    required this.open,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: open ? width : 0,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: open ? 1 : 0,
          child: open ? child : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// ----------------------------
/// SIDEBAR (DESKTOP)
/// ----------------------------

class _Sidebar extends StatelessWidget {
  final List<ShellSection> sections;
  final int sectionIndex;
  final int itemIndex;
  final List<bool> expanded;
  final String query;
  final TextEditingController searchCtrl;

  final void Function(int section) onToggleSection;
  final void Function(int section, int item) onTap;

  final int? farmId;
  final VoidCallback onClearSearch;

  const _Sidebar({
    required this.sections,
    required this.sectionIndex,
    required this.itemIndex,
    required this.expanded,
    required this.query,
    required this.searchCtrl,
    required this.onToggleSection,
    required this.onTap,
    required this.farmId,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLowest,
      child: SafeArea(
        child: Column(
          children: [
            // Header (marca + farm)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.grass, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trader Soja',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fazenda #$farmId',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar no menu...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar',
                          onPressed: onClearSearch,
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: cs.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                ),
              ),
            ),

            Divider(height: 1, color: cs.outlineVariant),

            // Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                children: [
                  for (int s = 0; s < sections.length; s++) ...[
                    _SectionHeader(
                      label: sections[s].label,
                      expanded: expanded[s],
                      onTap: () => onToggleSection(s),
                    ),
                    if (expanded[s])
                      for (int i = 0; i < sections[s].items.length; i++)
                        _NavTile(
                          item: sections[s].items[i],
                          selected: s == sectionIndex && i == itemIndex,
                          query: query,
                          onTap: () => onTap(s, i),
                        ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),

            // Footer (opcional)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dados isolados por fazenda',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final ShellItem item;
  final bool selected;
  final String query;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.query,
    required this.onTap,
  });

  bool get _matches {
    if (query.isEmpty) return true;
    return item.label.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    if (!_matches) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 1.2 : 0.8,
        ),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        leading: Icon(
          item.icon,
          color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
        title: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? cs.onPrimaryContainer : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
