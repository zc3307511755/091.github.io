import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update_info.dart';

class AppUpdateService {
  const AppUpdateService({
    this.metadataUrl = _defaultMetadataUrl,
    this.client,
    this.packageInfoLoader,
  });

  static const _defaultMetadataUrl = String.fromEnvironment(
    'APP_UPDATE_URL',
    defaultValue:
        'https://zc3307511755.github.io/091.github.io/app_update.json',
  );

  final String metadataUrl;
  final http.Client? client;
  final Future<PackageInfo> Function()? packageInfoLoader;

  Future<String> currentVersionLabel() async {
    final packageInfo = await _loadPackageInfo();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  Future<AppUpdateStatus> checkForUpdate() async {
    final packageInfo = await _loadPackageInfo();
    final activeClient = client ?? http.Client();
    late final http.Response response;
    try {
      response = await _loadMetadata(activeClient);
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }

    if (response.statusCode != 200) {
      throw AppUpdateException('版本信息读取失败：HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const AppUpdateException('版本信息格式不正确。');
    }

    return AppUpdateStatus(
      currentVersion: packageInfo.version,
      currentBuildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
      info: AppUpdateInfo.fromJson(decoded),
    );
  }

  Future<PackageInfo> _loadPackageInfo() {
    return packageInfoLoader?.call() ?? PackageInfo.fromPlatform();
  }

  Future<http.Response> _loadMetadata(http.Client activeClient) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await activeClient.get(
          _metadataUri(attempt),
          headers: const {
            'accept': 'application/json',
            'cache-control': 'no-cache, no-store, max-age=0',
            'pragma': 'no-cache',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode < 500 || attempt == 1) {
          return response;
        }
      } catch (error) {
        lastError = error;
        if (attempt == 1) {
          rethrow;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    throw AppUpdateException('版本信息读取失败：$lastError');
  }

  Uri _metadataUri(int attempt) {
    final uri = Uri.parse(metadataUrl);
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'v': '${DateTime.now().millisecondsSinceEpoch}-$attempt',
      },
    );
  }
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
