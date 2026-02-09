// lib/viewmodels/cbot/cbot_sources_vm.dart
import '../../core/api/api_exception.dart';
import '../../data/models/cbot/cbot_source_create.dart';
import '../../data/models/cbot/cbot_source_read.dart';
import '../../data/repositories/cbot_sources_repository.dart';
import '../base_view_model.dart';

class CbotSourcesVM extends BaseViewModel {
  final CbotSourcesRepository _repo;

  List<CbotSourceRead> rows = [];
  bool onlyActive = true;

  CbotSourcesVM(this._repo);

  Future<void> load({bool? onlyActive}) async {
    this.onlyActive = onlyActive ?? this.onlyActive;

    setLoading(true);
    clearError();
    try {
      rows = await _repo.list(onlyActive: this.onlyActive);
    } on ApiException catch (e) {
      setError(e);
      rows = [];
    } finally {
      setLoading(false);
    }
  }

  Future<bool> create({required String nome, bool ativo = true}) async {
    setLoading(true);
    clearError();
    try {
      await _repo.create(CbotSourceCreate(nome: nome, ativo: ativo));
      await load();
      return true;
    } on ApiException catch (e) {
      setError(e);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
