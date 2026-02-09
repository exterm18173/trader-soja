import '../../routes/app_routes.dart';
import 'auth_storage.dart';
import 'farm_storage.dart';

class AuthGuard {
  final AuthStorage authStorage;
  final FarmStorage farmStorage;

  AuthGuard({required this.authStorage, required this.farmStorage});

  Future<String> initialRoute() async {
  final token = await authStorage.getAccessToken();
  if (token == null || token.trim().isEmpty) return AppRoutes.login;

  final farmId = await farmStorage.getSelectedFarmId();
  if (farmId == null) return AppRoutes.farms;

  return AppRoutes.shell;
}

}
