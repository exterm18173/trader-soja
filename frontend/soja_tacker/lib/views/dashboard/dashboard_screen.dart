import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/dashboard/dashboard_vm.dart';


import '../../widgets/common/empty_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/kpi_cards_row.dart';
import 'widgets/usd_exposure_chart_card.dart';
import 'widgets/alerts_preview_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardVM>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardVM>(
      builder: (_, vm, __) {
        if (vm.loading && !vm.hasData) {
          return const Center(
            child: LoadingWidget(message: 'Carregando dashboard...'),
          );
        }

        if (vm.error != null && !vm.hasData) {
          return ErrorRetryWidget(
            title: 'Erro ao carregar dashboard',
            message: vm.error!.message,
            onRetry: vm.load,
          );
        }

        return RefreshIndicator(
          onRefresh: () => vm.load(force: true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DashboardHeader(vm: vm),
              const SizedBox(height: 12),

              KpiCardsRow(vm: vm),
              const SizedBox(height: 12),

              UsdExposureChartCard(vm: vm),
              const SizedBox(height: 12),

              AlertsPreviewCard(vm: vm),

              if (!vm.loading && !vm.hasData)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyStateWidget(
                    title: 'Sem dados ainda',
                    message:
                        'Cadastre contratos, despesas e cotações para ver os indicadores aqui.',
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
