// lib/core/auth/farm_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class FarmStorage {
  static const _kSelectedFarmId = 'selected_farm_id';

  Future<void> saveSelectedFarmId(int farmId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSelectedFarmId, farmId);
  }

  Future<int?> getSelectedFarmId() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getInt(_kSelectedFarmId);
    return v;
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kSelectedFarmId);
  }
}
