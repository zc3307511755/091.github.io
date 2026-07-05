class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minimumBuildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    this.publishedAt,
  });

  final String latestVersion;
  final int latestBuildNumber;
  final int minimumBuildNumber;
  final String? downloadUrl;
  final List<String> releaseNotes;
  final DateTime? publishedAt;

  bool hasUpdateFor(int currentBuildNumber) {
    return latestBuildNumber > currentBuildNumber;
  }

  bool requiresUpdateFor(int currentBuildNumber) {
    return minimumBuildNumber > currentBuildNumber;
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      latestBuildNumber: _readInt(json['latest_build_number']),
      minimumBuildNumber: _readInt(json['minimum_build_number']),
      downloadUrl: _readOptionalString(json['download_url']),
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
