class Couple {
  const Couple({
    required this.id,
    required this.userAId,
    this.userBId,
    required this.inviteCode,
    required this.status,
    this.pairedAt,
  });

  final String id;
  final String userAId;
  final String? userBId;
  final String inviteCode;
  final String status;
  final DateTime? pairedAt;

  bool get isActive => status == 'active' && userBId != null;

  String partnerId(String currentUserId) {
    if (userAId == currentUserId && userBId != null) {
      return userBId!;
    }
    return userAId;
  }

  factory Couple.fromMap(Map<String, dynamic> map) {
    final pairedAtValue = map['paired_at'];

    return Couple(
      id: map['id'] as String,
      userAId: map['user_a_id'] as String,
      userBId: map['user_b_id'] as String?,
      inviteCode: map['invite_code'] as String? ?? '',
      status: map['status'] as String,
      pairedAt: pairedAtValue == null
          ? null
          : DateTime.parse(pairedAtValue as String).toLocal(),
    );
  }
}
