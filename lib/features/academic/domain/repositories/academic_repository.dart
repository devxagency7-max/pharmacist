import '../entities/university_entity.dart';
import '../entities/faculty_entity.dart';

abstract class AcademicRepository {
  /// GET /universities — public, no auth. Cached client-side for 24h.
  Future<List<UniversityEntity>> getUniversities();

  /// GET /universities/{universityId}/faculties — public, no auth. Cached
  /// client-side for 24h, keyed per university.
  Future<List<FacultyEntity>> getFaculties(String universityId);
}
