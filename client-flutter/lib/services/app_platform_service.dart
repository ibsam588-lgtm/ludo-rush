import 'package:flutter/services.dart';

class AppVersionInfo {
  final String versionName;
  final int buildNumber;

  const AppVersionInfo({
    required this.versionName,
    required this.buildNumber,
  });
}

class AppPlatformService {
  static const MethodChannel _channel = MethodChannel('ludo_rush/app');

  static Future<AppVersionInfo> getVersionInfo() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getVersionInfo',
      );
      return AppVersionInfo(
        versionName: (raw?['versionName'] as String? ?? '').trim(),
        buildNumber: _readInt(raw?['buildNumber']),
      );
    } catch (_) {
      return const AppVersionInfo(versionName: '', buildNumber: 0);
    }
  }

  static Future<bool> openUrl(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('openUrl', {
        'url': url,
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
