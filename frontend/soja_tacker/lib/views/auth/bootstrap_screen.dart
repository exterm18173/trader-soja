import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_guard.dart';
import '../../core/auth/farm_context.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth/auth_vm.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    // 1) carrega fazenda do storage (se tiver)
    await context.read<FarmContext>().loadFromStorage();

    // 2) valida sessão no backend (/me) e limpa token se inválido
    await context.read<AuthVM>().bootstrap();

    // 3) decide rota final
    final route = await context.read<AuthGuard>().initialRoute();

    if (!mounted) return;

    // Padroniza: se estiver “logado”, manda pro shell
    final go = (route == AppRoutes.farms || route == AppRoutes.dashboard)
        ? AppRoutes.shell
        : route;

    Navigator.pushReplacementNamed(context, go);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
