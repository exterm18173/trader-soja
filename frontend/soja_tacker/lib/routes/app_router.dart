// lib/routes/app_router.dart
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../views/alerts/alert_events_screen.dart';
import '../views/alerts/alert_rules_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/cbot/cbot_quotes_screen.dart';
import '../views/cbot/cbot_sources_screen.dart';
import '../views/contracts/contract_detail_screen.dart';
import '../views/contracts/contracts_screen.dart';
import '../views/expenses/expenses_usd_screen.dart';
import '../views/farms/farms_screen.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/fx/fx_manual_points_screen.dart';
import '../views/fx/fx_model_run_detail_screen.dart';
import '../views/fx/fx_model_runs_screen.dart';
import '../views/fx/fx_quotes_screen.dart';
import '../views/fx/fx_sources_screen.dart';
import '../views/fx/fx_spot_screen.dart';
import '../views/hedges/hedges_screen.dart';
import '../views/rates/interest_rates_screen.dart';
import '../views/rates/offsets_screen.dart';
import '../views/shell/app_shell.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.farms:
        return MaterialPageRoute(builder: (_) => const FarmsScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case AppRoutes.interestRates:
        return MaterialPageRoute(builder: (_) => const InterestRatesScreen());
      case AppRoutes.offsets:
        return MaterialPageRoute(builder: (_) => const OffsetsScreen());

      case AppRoutes.expensesUsd:
        return MaterialPageRoute(builder: (_) => const ExpensesUsdScreen());
      case AppRoutes.fxSources:
        return MaterialPageRoute(builder: (_) => const FxSourcesScreen());

      case AppRoutes.fxSpot:
        return MaterialPageRoute(builder: (_) => const FxSpotScreen());
      case AppRoutes.fxManualPoints:
        return MaterialPageRoute(builder: (_) => const FxManualPointsScreen());
      case AppRoutes.fxQuotes:
        return MaterialPageRoute(builder: (_) => const FxQuotesScreen());
      case AppRoutes.fxModelRuns:
        return MaterialPageRoute(builder: (_) => const FxModelRunsScreen());
      case AppRoutes.cbotSources:
        return MaterialPageRoute(builder: (_) => const CbotSourcesScreen());

      case AppRoutes.cbotQuotes:
        return MaterialPageRoute(builder: (_) => const CbotQuotesScreen());
      case AppRoutes.contracts:
        return MaterialPageRoute(builder: (_) => const ContractsScreen());
      case AppRoutes.alertRules:
        return MaterialPageRoute(builder: (_) => const AlertRulesScreen());

      case AppRoutes.alertEvents:
        return MaterialPageRoute(builder: (_) => const AlertEventsScreen());
      case AppRoutes.shell:
        return MaterialPageRoute(builder: (_) => const AppShell());

      case AppRoutes.hedges:
        return MaterialPageRoute(
          builder: (_) => HedgesScreen(),
        );

      case AppRoutes.contractDetail:
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ContractDetailScreen(contractId: id),
        );

      case AppRoutes.fxModelRunDetail:
        final runId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => FxModelRunDetailScreen(runId: runId),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Rota não encontrada'))),
        );
    }
  }
}
