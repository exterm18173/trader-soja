// lib/data/repositories/dashboard_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/dashboard/usd_exposure_response.dart';

class DashboardRepository {
  final ApiClient api;
  DashboardRepository(this.api);

  Future<UsdExposureResponse> usdExposure({
    required int farmId,
    String? fromMes, // yyyy-mm-dd
    String? toMes,   // yyyy-mm-dd
  }) async {
    try {
      final res = await api.dio.get(
        '/farms/$farmId/dashboard/usd-exposure',
        queryParameters: {
          if (fromMes != null) 'from_mes': fromMes,
          if (toMes != null) 'to_mes': toMes,
        },
      );
      return UsdExposureResponse.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao carregar dashboard');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    if (e is ApiException) return e;
    return ApiException(message: fallback, details: e.toString());
  }
}
