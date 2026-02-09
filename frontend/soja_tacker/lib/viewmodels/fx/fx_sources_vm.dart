// lib/viewmodels/fx/fx_sources_vm.dart
import '../../core/api/api_exception.dart';
import '../../data/models/fx/fx_source_create.dart';
import '../../data/models/fx/fx_source_read.dart';
import '../../data/repositories/fx_sources_repository.dart';
import '../base_view_model.dart';

class FxSourcesVM extends BaseViewModel {
  final FxSourcesRepository _repo;

  List<FxSourceRead> rows = [];
  bool onlyActive = true;

  FxSourcesVM(this._repo);

  Future<void> load({bool? onlyActive}) async {
    if (onlyActive != null) this.onlyActive = onlyActive;

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
      await _repo.create(FxSourceCreate(nome: nome, ativo: ativo));
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
