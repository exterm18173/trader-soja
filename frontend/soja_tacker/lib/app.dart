// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth_guard.dart';
import 'core/auth/auth_storage.dart';
import 'core/auth/farm_context.dart';
import 'core/auth/farm_storage.dart';

import 'data/models/contracts_mtm/contracts_mtm_dashboard_vm.dart';
import 'data/repositories/alerts_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cbot_quotes_repository.dart';
import 'data/repositories/cbot_sources_repository.dart';
import 'data/repositories/contracts_mtm_repository.dart';
import 'data/repositories/contracts_repository.dart';
import 'data/repositories/farms_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/fx_manual_points_repository.dart';
import 'data/repositories/fx_model_repository.dart';
import 'data/repositories/fx_quotes_repository.dart';
import 'data/repositories/fx_sources_repository.dart';
import 'data/repositories/fx_spot_repository.dart';
import 'data/repositories/hedges_repository.dart';
import 'data/repositories/rates_repository.dart';
import 'data/repositories/expenses_usd_repository.dart';

import 'routes/app_router.dart';
import 'routes/app_routes.dart';

import 'theme/app_theme.dart';

import 'viewmodels/alerts/alert_events_vm.dart';
import 'viewmodels/alerts/alert_rules_vm.dart';
import 'viewmodels/auth/auth_vm.dart';
import 'viewmodels/cbot/cbot_quotes_vm.dart';
import 'viewmodels/cbot/cbot_sources_vm.dart';
import 'viewmodels/contracts/contract_detail_vm.dart';
import 'viewmodels/contracts/contracts_mtm_vm.dart';
import 'viewmodels/contracts/contracts_vm.dart';
import 'viewmodels/dashboard/contracts_result_dashboard_vm.dart';
import 'viewmodels/dashboard/dashboard_vm.dart';
import 'viewmodels/farms/farms_vm.dart';
import 'viewmodels/dashboard/usd_exposure_vm.dart';
import 'viewmodels/fx/fx_futures_quotes_vm.dart';
import 'viewmodels/fx/fx_manual_points_vm.dart';
import 'viewmodels/fx/fx_model_run_detail_vm.dart';
import 'viewmodels/fx/fx_model_runs_vm.dart';
import 'viewmodels/fx/fx_quotes_vm.dart';
import 'viewmodels/fx/fx_sources_vm.dart';
import 'viewmodels/fx/fx_spot_vm.dart';
import 'viewmodels/hedges/hedges_vm.dart';
import 'viewmodels/rates/interest_rates_vm.dart';
import 'viewmodels/rates/offsets_vm.dart';
import 'viewmodels/expenses/expenses_usd_vm.dart';

// ✅ Importa a BootstrapScreen
import 'views/auth/bootstrap_screen.dart';

class TraderSojaApp extends StatelessWidget {
  const TraderSojaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authStorage = AuthStorage();
    final farmStorage = FarmStorage();
    final apiClient = ApiClient(authStorage: authStorage);

    final authRepo = AuthRepository(apiClient);
    final farmsRepo = FarmsRepository(apiClient);
    final dashboardRepo = DashboardRepository(apiClient);
    final ratesRepo = RatesRepository(apiClient);
    final expensesRepo = ExpensesUsdRepository(apiClient);

    final farmContext = FarmContext(storage: farmStorage);

    final fxSourcesRepo = FxSourcesRepository(apiClient);
    final fxSpotRepo = FxSpotRepository(apiClient);
    final fxManualRepo = FxManualPointsRepository(apiClient);
    final fxQuotesRepo = FxQuotesRepository(apiClient);
    final fxModelRepo = FxModelRepository(apiClient);

    final cbotSourcesRepo = CbotSourcesRepository(apiClient);
    final cbotQuotesRepo = CbotQuotesRepository(apiClient);

    final contractsRepo = ContractsRepository(apiClient);
    final hedgesRepo = HedgesRepository(apiClient);
    final expensesUsdRepo = ExpensesUsdRepository(apiClient);
    final alertsRepo = AlertsRepository(apiClient);

    return MultiProvider(
      providers: [
        Provider.value(value: authStorage),
        Provider.value(value: farmStorage),
        Provider.value(value: apiClient),
        ChangeNotifierProvider.value(value: farmContext),

        // ✅ AuthGuard como provider (pra BootstrapScreen ler)
        Provider<AuthGuard>(
          create: (_) =>
              AuthGuard(authStorage: authStorage, farmStorage: farmStorage),
        ),

        Provider.value(value: authRepo),
        Provider.value(value: farmsRepo),
        Provider.value(value: dashboardRepo),
        Provider.value(value: ratesRepo),
        Provider.value(value: expensesRepo),
        Provider.value(value: fxSourcesRepo),
        Provider.value(value: fxSpotRepo),
        Provider.value(value: fxManualRepo),
        Provider.value(value: fxQuotesRepo),
        Provider.value(value: fxModelRepo),
        Provider.value(value: cbotSourcesRepo),
        Provider.value(value: cbotQuotesRepo),
        Provider.value(value: contractsRepo),
        Provider.value(value: hedgesRepo),
        Provider.value(value: expensesUsdRepo),
        Provider.value(value: alertsRepo),

        ChangeNotifierProvider(
          create: (_) => AlertRulesVM(alertsRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertEventsVM(alertsRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpensesUsdVM(expensesUsdRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (ctx) => HedgesVM(
            ctx.read<HedgesRepository>(),
            ctx.read<ContractsRepository>(),
            ctx.read<FarmContext>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => ContractsVM(contractsRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => ContractDetailVM(contractsRepo, farmContext),
        ),
        ChangeNotifierProvider(create: (_) => CbotSourcesVM(cbotSourcesRepo)),
        ChangeNotifierProvider(
          create: (_) => CbotQuotesVM(cbotQuotesRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => FxModelRunsVM(fxModelRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => FxModelRunDetailVM(fxModelRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => FxQuotesVM(fxQuotesRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => FxManualPointsVM(fxManualRepo, farmContext),
        ),
        ChangeNotifierProvider(create: (_) => FxSourcesVM(fxSourcesRepo)),
        ChangeNotifierProvider(
          create: (_) => FxSpotVM(fxSpotRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthVM(authRepo, authStorage, farmStorage),
        ),
        ChangeNotifierProvider(create: (_) => FarmsVM(farmsRepo, farmContext)),
        ChangeNotifierProvider(
          create: (_) => UsdExposureVM(dashboardRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => InterestRatesVM(ratesRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) => OffsetsVM(ratesRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FxFuturesQuotesVM(fxQuotesRepo, fxSourcesRepo, farmContext),
        ),
        Provider(
          create: (ctx) => ContractsMtmRepository(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ContractsMtmVM(ctx.read<ContractsMtmRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpensesUsdVM(expensesRepo, farmContext),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ContractsMtmDashboardVM(context.read<ContractsMtmRepository>()),
        ),

        ChangeNotifierProvider(
          create: (ctx) => DashboardVM(
            ctx.read<FarmContext>(),
            ctx.read<DashboardRepository>(),
            ctx.read<FxSpotRepository>(),
            ctx.read<CbotQuotesRepository>(),
            ctx.read<RatesRepository>(),
            ctx.read<AlertsRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ContractsResultDashboardVM(
            ctx.read<FarmContext>(),
            ctx.read<ContractsRepository>(),
            ctx.read<HedgesRepository>(),
            ctx.read<FxQuotesRepository>(),
            ctx.read<FxSpotRepository>(),
            ctx.read<CbotQuotesRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,

        // ✅ Sempre começa no bootstrap
        initialRoute: AppRoutes.bootstrap,

        // ✅ Mantém seu router
        onGenerateRoute: (settings) {
          // Se você usa o AppRouter, só garanta que ele sabe a rota bootstrap:
          if (settings.name == AppRoutes.bootstrap) {
            return MaterialPageRoute(builder: (_) => const BootstrapScreen());
          }
          return AppRouter.onGenerateRoute(settings);
        },
      ),
    );
  }
}
