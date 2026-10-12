import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pharmacist/core/constants/api_constants.dart';
import 'package:pharmacist/core/network/api_client.dart';
import '../../domain/entities/university_entity.dart';
import '../../domain/entities/faculty_entity.dart';
import '../../domain/repositories/academic_repository.dart';
import '../models/university_model.dart';
import '../models/faculty_model.dart';

/// Universities and faculties change once every few months at most (per
/// backend guidance), so both lists are cached client-side for 24h to avoid
/// re-fetching on every signup-screen visit.
const _cacheTtl = Duration(hours: 24);

class AcademicRepositoryImpl implements AcademicRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  AcademicRepositoryImpl(this._apiClient, this._prefs);

  @override
  Future<List<UniversityEntity>> getUniversities() async {
    const cacheKey = 'academic_universities_v1';
    final cached = _readCache(cacheKey);
    if (cached != null) {
      return cached.map((json) => UniversityModel.fromJson(json)).toList();
    }

    final response = await _apiClient.dio.get(ApiConstants.universities);
    final items = unwrapApiResponse(
      response,
      (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    await _writeCache(cacheKey, items);
    return items.map((json) => UniversityModel.fromJson(json)).toList();
  }

  @override
  Future<List<FacultyEntity>> getFaculties(String universityId) async {
    final cacheKey = 'academic_faculties_${universityId}_v1';
    final cached = _readCache(cacheKey);
    if (cached != null) {
      return cached.map((json) => FacultyModel.fromJson(json)).toList();
    }

    final response = await _apiClient.dio.get(
      ApiConstants.universityFaculties(universityId),
    );
    final items = unwrapApiResponse(
      response,
      (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    await _writeCache(cacheKey, items);
    return items.map((json) => FacultyModel.fromJson(json)).toList();
  }

  List<Map<String, dynamic>>? _readCache(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] ?? '');
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > _cacheTtl) {
        return null;
      }
      return (decoded['items'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, List<Map<String, dynamic>> items) {
    return _prefs.setString(
      key,
      jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
  }
}
