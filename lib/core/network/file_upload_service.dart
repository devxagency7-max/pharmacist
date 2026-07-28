import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

/// Result of `POST /api/files/upload` — the durable Cloudflare R2 key and a
/// freshly-signed URL for the uploaded file.
class UploadedFile {
  final String id;
  final String fileKey;
  final String url;
  final String previewUrl;

  UploadedFile({
    required this.id,
    this.fileKey = '',
    required this.url,
    required this.previewUrl,
  });
}

/// Uploads real files to the backend's Cloudflare R2-backed storage.
///
/// This must be called before attaching any `uploadedFileId` to a document or
/// profile field — the backend has no "mock storage" mode, and a
/// client-invented URL or ID will be silently unreadable by reviewers.
class FileUploadService {
  final ApiClient _apiClient;

  FileUploadService(this._apiClient);

  /// [fileType] must be one of the backend's `FileType` enum values, e.g.
  /// `Identification`, `License`, or `Other`.
  Future<UploadedFile> uploadFile({
    required String filePath,
    required String fileType,
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'fileType': fileType,
    });

    final response = await _apiClient.dio.post(
      ApiConstants.filesUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = unwrapApiResponse(response, (json) => json as Map<String, dynamic>);
    final preview = data['previewUrl'] as String? ?? data['url'] as String? ?? '';
    return UploadedFile(
      id: data['id'] as String? ?? '',
      fileKey: data['fileKey'] as String? ?? '',
      url: preview,
      previewUrl: preview,
    );
  }
}
