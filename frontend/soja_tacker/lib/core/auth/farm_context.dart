// lib/core/auth/farm_context.dart
import 'package:flutter/foundation.dart';

import 'farm_storage.dart';

class FarmContext extends ChangeNotifier {
  final FarmStorage storage;

  FarmContext({required this.storage});

  int? _farmId;
  int? get farmId => _farmId;

  bool get hasFarm => _farmId != null;

  Future<void> loadFromStorage() async {
    _farmId = await storage.getSelectedFarmId();
    notifyListeners();
  }

  Future<void> setFarm(int farmId) async {
    _farmId = farmId;
    await storage.saveSelectedFarmId(farmId);
    notifyListeners();
  }

  Future<void> clear() async {
    _farmId = null;
    await storage.clear();
    notifyListeners();
  }
}
