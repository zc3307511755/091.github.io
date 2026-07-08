class UserPresence {
  const UserPresence({
    required this.userId,
    required this.lastSeenAt,
  });

  final String userId;
  final DateTime lastSeenAt;

  bool get isOnline {
    return DateTime.now().difference(lastSeenAt).inSeconds <= 90;
  }

  factory UserPresence.fromMap(Map<String, dynamic> map) {
    return UserPresence(
      userId: map['user_id'] as String,
      lastSeenAt: DateTime.parse(map['last_seen_at'] as String).toLocal(),
    );
  }
}
