abstract class DeviceRemoteDataSource {
  Future<String> registerDevice({
    required String deviceType,
    String? deviceName,
    required String fcmToken,
  });

  Future<void> unregisterDevice(String deviceId);
}
