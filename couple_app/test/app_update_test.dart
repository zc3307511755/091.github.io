import 'dart:convert';

import 'package:couple_app/models/app_update_info.dart';
import 'package:couple_app/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('AppUpdateInfo', () {
    test('normalizes split APK version codes using the base build number', () {
      final info = AppUpdateInfo.fromJson({
        'latest_version': '0.2.6',
        'latest_build_number': 2008,
        'latest_base_build_number': 8,
        'minimum_build_number': 1,
        'download_url': 'https://example.com/app.apk',
        'release_notes': <String>[],
      });

      expect(info.hasUpdateFor(2007), isTrue);
      expect(info.hasUpdateFor(7), isTrue);
      expect(info.hasUpdateFor(2008), isFalse);
      expect(info.hasUpdateFor(8), isFalse);
    });

    test('falls back to semantic version comparison', () {
      final status = AppUpdateStatus(
        currentVersion: '0.2.5',
        currentBuildNumber: 8,
        info: AppUpdateInfo.fromJson({
          'latest_version': '0.2.6',
          'latest_build_number': 2008,
          'latest_base_build_number': 8,
          'minimum_build_number': 1,
          'download_url': 'https://example.com/app.apk',
          'release_notes': <String>[],
        }),
      );

      expect(status.hasUpdate, isTrue);
      expect(status.latestLabel, '0.2.6+8');
    });
  });

  test('metadata request bypasses caches and detects the next Android build',
      () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'latest_version': '0.2.6',
          'latest_build_number': 2008,
          'latest_base_build_number': 8,
          'minimum_build_number': 1,
          'download_url': 'https://example.com/app.apk',
          'release_notes': ['Update detection fixed.'],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = AppUpdateService(
      metadataUrl: 'https://example.com/app_update.json?channel=stable',
      client: client,
      packageInfoLoader: () async => PackageInfo(
        appName: '我们俩',
        packageName: 'com.example.couple_app',
        version: '0.2.5',
        buildNumber: '2007',
      ),
    );

    final status = await service.checkForUpdate();

    expect(requestedUri.queryParameters['channel'], 'stable');
    expect(requestedUri.queryParameters['v'], isNotEmpty);
    expect(status.hasUpdate, isTrue);
    expect(status.latestLabel, '0.2.6+8');
  });
}
