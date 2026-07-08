class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    this.latestBaseBuildNumber,
    required this.minimumBuildNumber,
    required this.downloadUrl,
    this.downloadPageUrl,
    required this.releaseNotes,
    this.publishedAt,
  });

  final String latestVersion;
  final int latestBuildNumber;
  final int? latestBaseBuildNumber;
  final int minimumBuildNumber;
  final String? downloadUrl;
  final String? downloadPageUrl;
  final List<String> releaseNotes;
  final DateTime? publishedAt;

  bool hasUpdateFor(int currentBuildNumber) {
    final baseBuildNumber = latestBaseBuildNumber;
    if (baseBuildNumber != null && baseBuildNumber > 0) {
      return baseBuildNumber > _normalizeBuildNumber(currentBuildNumber);
    }

    return latestBuildNumber > currentBuildNumber;
  }

  bool requiresUpdateFor(int currentBuildNumber) {
    return minimumBuildNumber > currentBuildNumber;
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      latestBuildNumber: _readInt(json['latest_build_number']),
      latestBaseBuildNumber: _readOptionalInt(json['latest_base_build_number']),
      minimumBuildNumber: _readInt(json['minimum_build_number']),
      downloadUrl: _readOptionalString(json['download_url']),
      downloadPageUrl: _readOptionalString(json['download_page_url']),
      releaseNotes: _readNotes(json['release_notes']),
      publishedAt: _readDate(json['published_at']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int? _readOptionalInt(Object? value) {
    if (value == null) {
      return null;
    }
    final parsed = _readInt(value);
    return parsed > 0 ? parsed : null;
  }

  static int _normalizeBuildNumber(int value) {
    if (value >= 1000) {
      return value % 1000;
    }
    return value;
  }

  static String? _readOptionalString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _readNotes(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.info,
  });

  final String currentVersion;
  final int currentBuildNumber;
  final AppUpdateInfo info;

  bool get hasUpdate => info.hasUpdateFor(currentBuildNumber);
  bool get requiresUpdate => info.requiresUpdateFor(currentBuildNumber);

  String get currentLabel => '$currentVersion+$currentBuildNumber';
  String get latestLabel => '${info.latestVersion}+${info.latestBuildNumber}';
}
