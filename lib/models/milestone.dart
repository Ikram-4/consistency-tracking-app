import 'package:uuid/uuid.dart';

/// Represents a milestone within a goal.
///
/// Milestones are discrete checkpoints that mark progress toward a goal.
/// Each milestone has a title and an optional target date.
class Milestone {
  static const _sentinel = Object();

  final String id;
  final String title;
  final DateTime? targetDate;
  final bool isCompleted;

  Milestone({
    String? id,
    required this.title,
    this.targetDate,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  Milestone copyWith({
    String? id,
    String? title,
    Object? targetDate = _sentinel,
    bool? isCompleted,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate == _sentinel
          ? this.targetDate
          : targetDate as DateTime?,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetDate': targetDate?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'] as String,
      title: map['title'] as String,
      targetDate: map['targetDate'] != null
          ? DateTime.parse(map['targetDate'] as String)
          : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'Milestone(id: $id, title: $title, targetDate: $targetDate, '
        'isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Milestone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
