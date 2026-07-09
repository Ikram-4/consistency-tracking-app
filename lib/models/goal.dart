import 'package:uuid/uuid.dart';

import 'package:phantom/models/milestone.dart';

/// The type of progress calculation used for a goal.
enum ProgressType {
  /// Progress is based on completed milestones.
  milestone,

  /// Progress is based on a numeric target count (e.g. '150 problems').
  count,

  /// Progress is based on elapsed time relative to total duration.
  timeElapsed,
}

/// Represents a user-defined goal with optional milestones and tracking metadata.
///
/// Goals belong to a user-defined domain (free text) and track progress
/// via milestones, numeric counts, or elapsed time.
class Goal {
  static const _sentinel = Object();

  final String id;
  final String title;
  final String domain;
  final DateTime targetDate;
  final String? whyStatement;
  final int? targetCount;
  final List<Milestone> milestones;
  final DateTime createdAt;
  final bool isArchived;

  Goal({
    String? id,
    required this.title,
    required this.domain,
    required this.targetDate,
    this.whyStatement,
    this.targetCount,
    List<Milestone>? milestones,
    DateTime? createdAt,
    this.isArchived = false,
  })  : id = id ?? const Uuid().v4(),
        milestones = milestones ?? [],
        createdAt = createdAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// Number of milestones that have been completed.
  int get completedMilestoneCount =>
      milestones.where((m) => m.isCompleted).length;

  /// Days remaining until the target date from today.
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  /// Total number of days between creation and the target date.
  int get totalDays => targetDate.difference(createdAt).inDays;

  /// Number of days elapsed since the goal was created.
  int get daysElapsed => DateTime.now().difference(createdAt).inDays;

  /// The progress percentage as a double between 0.0 and 1.0.
  ///
  /// - If milestones exist: ratio of completed to total milestones.
  /// - If [targetCount] is set (no milestones): returns 0.0 — actual progress
  ///   depends on check-in counts and is computed in the provider layer.
  /// - Otherwise: ratio of elapsed days to total days, clamped to [0.0, 1.0].
  double get progressPercent {
    if (milestones.isNotEmpty) {
      return completedMilestoneCount / milestones.length;
    }
    if (targetCount != null) {
      return 0.0;
    }
    if (totalDays <= 0) return 1.0;
    return (daysElapsed / totalDays).clamp(0.0, 1.0);
  }

  /// The strategy used to compute progress for this goal.
  ProgressType get progressType {
    if (milestones.isNotEmpty) return ProgressType.milestone;
    if (targetCount != null) return ProgressType.count;
    return ProgressType.timeElapsed;
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  Goal copyWith({
    String? id,
    String? title,
    String? domain,
    DateTime? targetDate,
    Object? whyStatement = _sentinel,
    Object? targetCount = _sentinel,
    List<Milestone>? milestones,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      targetDate: targetDate ?? this.targetDate,
      whyStatement: whyStatement == _sentinel
          ? this.whyStatement
          : whyStatement as String?,
      targetCount: targetCount == _sentinel
          ? this.targetCount
          : targetCount as int?,
      milestones: milestones ?? this.milestones,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'domain': domain,
      'targetDate': targetDate.toIso8601String(),
      'whyStatement': whyStatement,
      'targetCount': targetCount,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      domain: map['domain'] as String,
      targetDate: DateTime.parse(map['targetDate'] as String),
      whyStatement: map['whyStatement'] as String?,
      targetCount: map['targetCount'] as int?,
      milestones: (map['milestones'] as List<dynamic>?)
              ?.map((e) => Milestone.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, title: $title, domain: $domain, '
        'targetDate: $targetDate, whyStatement: $whyStatement, '
        'targetCount: $targetCount, milestones: $milestones, '
        'createdAt: $createdAt, isArchived: $isArchived)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Goal && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
