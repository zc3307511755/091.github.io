class CouponRequest {
  const CouponRequest({
    required this.id,
    required this.coupleId,
    required this.requesterId,
    required this.approverId,
    required this.title,
    this.description,
    this.expiresAt,
    required this.status,
    this.responseNote,
    this.couponId,
    this.decidedAt,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String requesterId;
  final String approverId;
  final String title;
  final String? description;
  final DateTime? expiresAt;
  final String status;
  final String? responseNote;
  final String? couponId;
  final DateTime? decidedAt;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isExpired {
    final expires = expiresAt;
    if (expires == null || !isPending) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(expires.year, expires.month, expires.day);
    return end.isBefore(today);
  }

  factory CouponRequest.fromMap(Map<String, dynamic> map) {
    final expiresAtValue = map['expires_at'];
    final decidedAtValue = map['decided_at'];

    return CouponRequest(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      requesterId: map['requester_id'] as String,
      approverId: map['approver_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      expiresAt: expiresAtValue == null
          ? null
          : DateTime.parse(expiresAtValue as String),
      status: map['status'] as String,
      responseNote: map['response_note'] as String?,
      couponId: map['coupon_id'] as String?,
      decidedAt: decidedAtValue == null
          ? null
          : DateTime.parse(decidedAtValue as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
