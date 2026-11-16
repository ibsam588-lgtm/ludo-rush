import 'dart:convert';
import 'package:http/http.dart' as http;

/// Only public, available App Store versions can request a production update.
/// A TestFlight upload is deliberately not an App Store release.
class AppStoreReleaseService {
  static const appId = 6834993861;
  static const bundleId = 'com.corsairlabs.ludocheer';

  static Future<String?> latestVersion({
    String countryCode = 'US',
    http.Client? client,
  }) async {
    final ownsClient = client == null;
    final requester = client ?? http.Client();
    try {
      final country = RegExp(r'^[A-Za-z]{2}$').hasMatch(countryCode)
          ? countryCode.toUpperCase()
          : 'US';
      final response = await requester
          .get(
            Uri.https('itunes.apple.com', '/lookup', {
              'id': '$appId',
              'country': country,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      for (final row in body['results'] as List<dynamic>? ?? const []) {
        if (row is! Map<String, dynamic> ||
            row['trackId'] != appId ||
            row['bundleId'] != bundleId)
          continue;
        final version = row['version'];
        if (version is String && _parts(version) != null) return version;
      }
    } catch (_) {
      // An unavailable catalog must not manufacture an update or block play.
      // The authenticated backend's existing minimum-build policy still applies.
    } finally {
      if (ownsClient) requester.close();
    }
    return null;
  }

  static bool isNewer(String published, String installed) {
    final latest = _parts(published);
    final current = _parts(installed);
    if (latest == null || current == null) return false;
    for (var i = 0; i < 3; i++) {
      final comparison = latest[i].compareTo(current[i]);
      if (comparison != 0) return comparison > 0;
    }
    return false;
  }

  static List<int>? _parts(String value) {
    if (!RegExp(r'^\d+(\.\d+){0,2}$').hasMatch(value)) return null;
    final parts = value.split('.').map(int.parse).toList();
    return [...parts, ...List.filled(3 - parts.length, 0)];
  }
}
