import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ludo_rush/services/app_store_release_service.dart';

void main() {
  test('published version comparison is numeric and never downgrades', () {
    expect(AppStoreReleaseService.isNewer('1.0.10', '1.0.9'), isTrue);
    expect(AppStoreReleaseService.isNewer('1.0', '1.0.0'), isFalse);
    expect(AppStoreReleaseService.isNewer('1.0.0', '1.1.0'), isFalse);
    expect(AppStoreReleaseService.isNewer('2.0', '1.9.9'), isTrue);
    expect(AppStoreReleaseService.isNewer('bad', '1.0.0'), isFalse);
  });
  test('looks up only the verified app in the requested storefront', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'itunes.apple.com');
      expect(request.url.queryParameters['country'], 'GB');
      return http.Response(
        jsonEncode({
          'results': [
            {
              'trackId': 6834993861,
              'bundleId': 'com.corsairlabs.ludocheer',
              'version': '1.1.0',
            },
          ],
        }),
        200,
      );
    });
    expect(
      await AppStoreReleaseService.latestVersion(
        countryCode: 'gb',
        client: client,
      ),
      '1.1.0',
    );
  });
  test(
    'unpublished apps, wrong identities and malformed versions cannot block play',
    () async {
      for (final rows in [
        [],
        [
          {
            'trackId': 123,
            'bundleId': 'com.corsairlabs.ludocheer',
            'version': '9.0',
          },
        ],
        [
          {'trackId': 6834993861, 'bundleId': 'other.app', 'version': '9.0'},
        ],
        [
          {
            'trackId': 6834993861,
            'bundleId': 'com.corsairlabs.ludocheer',
            'version': 'invalid',
          },
        ],
      ]) {
        expect(
          await AppStoreReleaseService.latestVersion(
            client: MockClient(
              (_) async => http.Response(jsonEncode({'results': rows}), 200),
            ),
          ),
          isNull,
        );
      }
    },
  );
  test('catalog failures keep the backend update policy available', () async {
    expect(
      await AppStoreReleaseService.latestVersion(
        client: MockClient((_) async => http.Response('unavailable', 503)),
      ),
      isNull,
    );
  });
}
