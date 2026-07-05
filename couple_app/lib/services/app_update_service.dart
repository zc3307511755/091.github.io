import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update_info.dart';

class AppUpdateService {
  const AppUpdateService({
    this.metadataUrl = _defaultMetadataUrl,
  });

  static const _defaultMetadataUrl = String.fromEnvironment(
    'APP_UPDATE_URL',
    defaultValue:
        'https://zc3307511755.github.io/091.github.io/app_update.json',
  );

  final String metadataUrl;

  Future<String> currentVersionLabel() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  Future<AppUpdateStatus> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final response = await http.get(
      Uri.parse(metadataUrl),
      headers: const {
        'cache-control': 'no-cache',
        'pragma': 'no-cache',
      },
    ).timeout(const Duration(seconds: 12));

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
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
