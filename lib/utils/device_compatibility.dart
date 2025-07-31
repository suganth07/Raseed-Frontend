import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceCompatibility {
  static Future<DeviceInfo> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return DeviceInfo(
          platform: 'web',
          isSupported: true,
          reason: 'Testing mode enabled - Google Wallet functionality available for demonstration',
        );
      }

      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidInfo();
        return androidInfo;
      }

      if (Platform.isIOS) {
        return DeviceInfo(
          platform: 'ios',
          isSupported: true,
          reason: 'Testing mode enabled - Google Wallet functionality available for demonstration',
        );
      }

      return DeviceInfo(
        platform: 'unknown',
        isSupported: true,
        reason: 'Testing mode enabled - Google Wallet functionality available for demonstration',
      );
    } catch (e) {
      return DeviceInfo(
        platform: 'unknown',
        isSupported: true,
        reason: 'Testing mode enabled - assuming device compatibility',
      );
    }
  }

  static Future<DeviceInfo> _getAndroidInfo() async {
    try {
      const platform = MethodChannel('raseed.com/device_info');
      final Map<String, dynamic> deviceData = 
          await platform.invokeMethod('getDeviceInfo') as Map<String, dynamic>;
      
      final int sdkInt = deviceData['sdkInt'] ?? 0;
      final String model = deviceData['model'] ?? 'Unknown';
      final String manufacturer = deviceData['manufacturer'] ?? 'Unknown';
      
      // Google Wallet requires Android 7.0 (API level 24) or higher
      if (sdkInt < 24) {
        return DeviceInfo(
          platform: 'android',
          isSupported: false,
          reason: 'Google Wallet requires Android 7.0 or higher (current: API $sdkInt)',
          deviceModel: '$manufacturer $model',
          apiLevel: sdkInt,
        );
      }

      return DeviceInfo(
        platform: 'android',
        isSupported: true,
        reason: 'Device is compatible with Google Wallet',
        deviceModel: '$manufacturer $model',
        apiLevel: sdkInt,
      );
    } catch (e) {
      // Fallback for when native method channel is not available
      return DeviceInfo(
        platform: 'android',
        isSupported: true,
        reason: 'Device compatibility assumed (unable to verify API level)',
      );
    }
  }

  static Future<bool> checkWalletSupport() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo.isSupported;
  }

  static Future<String> getCompatibilityMessage() async {
    final deviceInfo = await getDeviceInfo();
    if (deviceInfo.isSupported) {
      return 'Your device supports Google Wallet functionality.';
    } else {
      return 'Compatibility Issue: ${deviceInfo.reason}';
    }
  }
}

class DeviceInfo {
  final String platform;
  final bool isSupported;
  final String reason;
  final String? deviceModel;
  final int? apiLevel;

  DeviceInfo({
    required this.platform,
    required this.isSupported,
    required this.reason,
    this.deviceModel,
    this.apiLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'isSupported': isSupported,
      'reason': reason,
      'deviceModel': deviceModel,
      'apiLevel': apiLevel,
    };
  }

  @override
  String toString() {
    return 'DeviceInfo(platform: $platform, supported: $isSupported, reason: $reason, model: $deviceModel, api: $apiLevel)';
  }
}
