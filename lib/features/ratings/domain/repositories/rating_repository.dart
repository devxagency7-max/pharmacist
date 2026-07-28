import 'package:pharmacist/core/network/paged_result.dart';
import '../entities/rating_entity.dart';

abstract class RatingRepository {
  /// GET /ratings/pharmacist/{pharmacistId} — AllowAnonymous, page size default 10.
  Future<PagedResult<RatingEntity>> getPharmacistRatings(
    String pharmacistId, {
    int page = 1,
    int pageSize = 10,
  });
}
