class Coupon {
  const Coupon({
    required this.id,
    required this.coupleId,
    required this.issuerId,
    required this.receiverId,
    required this.title,
    this.description,
    required this.status,
    this.expiresAt,
    this.sourceRequestId,
    this.usedAt,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String issuerId;
  final String receiverId;
  final String title;
  final String? description;
  final String status;
  final DateTime? expiresAt;
  final String? sourceRequestId;
  final DateTime? usedAt;
  final DateTime createdAt;

  bool get isUnused => status == 'unused';
  bool get isUsed => status == 'used';
  bool get isExpired {
    final expires = expiresAt;
    if (expires == null || !isUnused) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(expires.year, expires.month, expires.day);
    return end.isBefore(today);
  }

  bool get canUse => isUnused && !isExpired;

  factory Coupon.fromMap(Map<String, dynamic> map) {
    final usedAtValue = map['used_at'];
    final expiresAtValue = map['expires_at'];

    return Coupon(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      issuerId: map['issuer_id'] as String,
      receiverId: map['receiver_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      expiresAt: expiresAtValue == null
          ? null
          : DateTime.parse(expiresAtValue as String),
      sourceRequestId: map['source_request_id'] as String?,
      usedAt: usedAtValue == null
          ? null
          : DateTime.parse(usedAtValue as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
