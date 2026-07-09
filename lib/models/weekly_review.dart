import 'package:uuid/uuid.dart';

/// Represents a weekly review and reflection.
///
/// At the end of each week, the user reflects on what worked, what didn't,
/// and can adjust practice targets for the upcoming week.
class WeeklyReview {
  final String id;
  final DateTime weekStartDate;
  final String whatWorked;
  final String whatDidnt;
  final Map<String, int> adjustments;
  final DateTime createdAt;

  WeeklyReview({
    String? id,
    required this.weekStartDate,
    required this.whatWorked,
    required this.whatDidnt,
    Map<String, int>? adjustments,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        adjustments = adjustments ?? {},
        createdAt = createdAt ?? DateTime.now();

  WeeklyReview copyWith({
    String? id,
    DateTime? weekStartDate,
    String? whatWorked,
    String? whatDidnt,
    Map<String, int>? adjustments,
    DateTime? createdAt,
  }) {
    return WeeklyReview(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      whatWorked: whatWorked ?? this.whatWorked,
      whatDidnt: whatDidnt ?? this.whatDidnt,
      adjustments: adjustments ?? this.adjustments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekStartDate': weekStartDate.toIso8601String(),
      'whatWorked': whatWorked,
      'whatDidnt': whatDidnt,
      'adjustments': Map<String, dynamic>.from(adjustments),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyReview.fromMap(Map<String, dynamic> map) {
    return WeeklyReview(
      id: map['id'] as String,
      weekStartDate: DateTime.parse(map['weekStartDate'] as String),
      whatWorked: map['whatWorked'] as String,
      whatDidnt: map['whatDidnt'] as String,
      adjustments: (map['adjustments'] as Map?)?.map(
            (key, value) => MapEntry(key as String, value as int),
          ) ??
          {},
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'WeeklyReview(id: $id, weekStartDate: $weekStartDate, '
        'whatWorked: $whatWorked, whatDidnt: $whatDidnt, '
        'adjustments: $adjustments, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyReview &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
