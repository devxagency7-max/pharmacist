import 'package:pharmacist/core/network/api_client.dart';
import 'device_remote_datasource.dart';

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final ApiClient _apiClient;

  DeviceRemoteDataSourceImpl(this._apiClient);

  @override
  Future<String> registerDevice({
    required String deviceType,
    String? deviceName,
    required String fcmToken,
  }) async {
    final response = await _apiClient.dio.post(
      'users/me/devices',
      data: {
        'deviceType': deviceType,
        if (deviceName != null) 'deviceName': deviceName,
        'fcmToken': fcmToken,
      },
    );
    return unwrapApiResponse(response, (json) => json['id'] as String? ?? '');
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    await _apiClient.dio.delete('users/me/devices/$deviceId');
  }
}
