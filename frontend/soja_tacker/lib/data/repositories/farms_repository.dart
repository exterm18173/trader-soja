// lib/data/repositories/farms_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/farms/farm_create.dart';
import '../models/farms/farm_membership_read.dart';
import '../models/farms/farm_read.dart';
import '../models/farms/farm_update.dart';

class FarmsRepository {
  final ApiClient api;
  FarmsRepository(this.api);

  Future<List<FarmMembershipRead>> minhasFazendas() async {
    try {
      final res = await api.dio.get('/farms');
      final list = (res.data as List).cast<dynamic>();
      return list
          .map((e) => FarmMembershipRead.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao listar fazendas');
    }
  }

  Future<FarmRead> criar(FarmCreate payload) async {
    try {
      final res = await api.dio.post('/farms', data: payload.toJson());
      return FarmRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao criar fazenda');
    }
  }

  Future<FarmRead> obter(int farmId) async {
    try {
      final res = await api.dio.get('/farms/$farmId');
      return FarmRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao obter fazenda');
    }
  }

  Future<FarmRead> atualizar(int farmId, FarmUpdate payload) async {
    try {
      final res = await api.dio.patch('/farms/$farmId', data: payload.toJson());
      return FarmRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao atualizar fazenda');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
