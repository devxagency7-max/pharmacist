import '../../domain/entities/university_entity.dart';

class UniversityModel extends UniversityEntity {
  UniversityModel({
    required super.id,
    required super.arabicName,
    required super.englishName,
  });

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
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
