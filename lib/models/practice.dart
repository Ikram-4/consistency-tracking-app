import 'package:uuid/uuid.dart';

/// Represents a recurring practice linked to a [Goal].
///
/// A practice defines a repeatable activity (e.g. "Solve LeetCode problems")
/// with a weekly frequency target (e.g. 4 times per week).
class Practice {
  final String id;
  final String goalId;
  final String title;
  final int weeklyTarget;
  final DateTime createdAt;
  final bool isActive;

  Practice({
    String? id,
    required this.goalId,
    required this.title,
    required this.weeklyTarget,
    DateTime? createdAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Practice copyWith({
    String? id,
    String? goalId,
    String? title,
    int? weeklyTarget,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Practice(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'weeklyTarget': weeklyTarget,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Practice.fromMap(Map<String, dynamic> map) {
    return Practice(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: map['title'] as String,
      weeklyTarget: map['weeklyTarget'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'Practice(id: $id, goalId: $goalId, title: $title, '
        'weeklyTarget: $weeklyTarget, createdAt: $createdAt, '
        'isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Practice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
