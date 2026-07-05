class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
  });

  final String id;
  final String nickname;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      nickname: map['nickname'] as String? ?? 'User',
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
