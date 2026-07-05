class Anniversary {
  const Anniversary({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.eventDate,
    required this.type,
    required this.repeatYearly,
    required this.createdBy,
  });

  final String id;
  final String coupleId;
  final String title;
  final DateTime eventDate;
  final String type;
  final bool repeatYearly;
  final String createdBy;

  factory Anniversary.fromMap(Map<String, dynamic> map) {
    return Anniversary(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      title: map['title'] as String,
      eventDate: DateTime.parse(map['event_date'] as String),
      type: map['type'] as String,
      repeatYearly: map['repeat_yearly'] as bool? ?? false,
      createdBy: map['created_by'] as String,
    );
  }

  DateTime get nextDate {
    if (!repeatYearly) {
      return eventDate;
    }

    final now = DateTime.now();
    var next = DateTime(now.year, eventDate.month, eventDate.day);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = DateTime(now.year + 1, eventDate.month, eventDate.day);
    }
    return next;
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextDate.difference(today).inDays;
  }
}
