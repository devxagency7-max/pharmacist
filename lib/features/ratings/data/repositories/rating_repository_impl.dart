import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import 'package:pharmacist/core/network/paged_result.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';
import '../models/rating_model.dart';

class RatingRepositoryImpl implements RatingRepository {
  final ApiClient _apiClient;

  RatingRepositoryImpl(this._apiClient);

  @override
  Future<PagedResult<RatingEntity>> getPharmacistRatings(
    String pharmacistId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.dio.get(
      ApiConstants.pharmacistRatings(pharmacistId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return unwrapApiResponse(
      response,
      (json) => PagedResult.fromJson(json, RatingModel.fromJson),
    );
  }
}
