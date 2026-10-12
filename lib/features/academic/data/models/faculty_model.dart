import '../../domain/entities/faculty_entity.dart';

class FacultyModel extends FacultyEntity {
  FacultyModel({
    required super.id,
    required super.arabicName,
    required super.englishName,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      id: json['id'] ?? '',
      arabicName: json['arabicName'] ?? '',
      englishName: json['englishName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'arabicName': arabicName,
    'englishName': englishName,
  };
}
