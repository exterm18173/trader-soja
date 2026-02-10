import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/contracts_mtm/contracts_mtm_response.dart';
import '../../data/repositories/contracts_mtm_repository.dart';

class ContractsMtmVM extends ChangeNotifier {
  final ContractsMtmRepository repo;

  ContractsMtmVM(this.repo);

  bool loading = false;
  Object? error;

  ContractsMtmResponse? data;

  // filtros
  String mode = 'both'; // system|manual|both
  bool onlyOpen = true;
  String? refMes; // YYYY-MM-01
  String defaultSymbol = 'ZS=F';
  int limit = 200;

  Timer? _poll;

  Future<void> load({required int farmId}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await repo.mtm(
        farmId: farmId,
        mode: mode,
        onlyOpen: onlyOpen,
        refMes: refMes,
        defaultSymbol: defaultSymbol,
        limit: limit,
      );
      data = res;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void startRealtimePolling({
    required int farmId,
    Duration every = const Duration(seconds: 10),
  }) {
    stopRealtimePolling();
    _poll = Timer.periodic(every, (_) => load(farmId: farmId));
  }

  void stopRealtimePolling() {
    _poll?.cancel();
    _poll = null;
  }

  void setMode(String v, {required int farmId}) {
    if (mode == v) return;
    mode = v;
    load(farmId: farmId);
  }

  void toggleOnlyOpen({required int farmId}) {
    onlyOpen = !onlyOpen;
    load(farmId: farmId);
  }

  void setRefMes(String? v, {required int farmId}) {
    refMes = (v == null || v.trim().isEmpty) ? null : v.trim();
    load(farmId: farmId);
  }

  void setDefaultSymbol(String v, {required int farmId}) {
    defaultSymbol = v.trim().isEmpty ? 'ZS=F' : v.trim();
    load(farmId: farmId);
  }

  void setLimit(int v, {required int farmId}) {
    limit = v.clamp(1, 2000);
    load(farmId: farmId);
  }

  String errMsg(Object? e) {
    if (e is ApiException) return e.message;
    return e?.toString() ?? 'Erro desconhecido';
  }

  @override
  void dispose() {
    stopRealtimePolling();
    super.dispose();
  }
}
