class Coupon {
  const Coupon({
    required this.id,
    required this.coupleId,
    required this.issuerId,
    required this.receiverId,
    required this.title,
    this.description,
    required this.status,
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
  final DateTime? usedAt;
  final DateTime createdAt;

  bool get isUnused => status == 'unused';

  factory Coupon.fromMap(Map<String, dynamic> map) {
    final usedAtValue = map['used_at'];

    return Coupon(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      issuerId: map['issuer_id'] as String,
      receiverId: map['receiver_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      usedAt: usedAtValue == null
          ? null
          : DateTime.parse(usedAtValue as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
