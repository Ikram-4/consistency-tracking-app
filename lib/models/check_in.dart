import 'package:uuid/uuid.dart';

/// Represents a single check-in (practice session log).
///
/// Each check-in records what the user actually did during a practice session,
/// including effort level, optional duration, and a required note.
class CheckIn {
  static const _sentinel = Object();

  final String id;
  final String practiceId;
  final String goalId;
  final String note;
  final int effortLevel;
  final int? durationMinutes;
  final DateTime timestamp;

  /// Relative effort/duration weight for this check-in, used by the habit
  /// model's diminishing-returns consistency formula.
  ///
  /// Defaults to 1.0 for a standard session. A short warm-up might be 0.5;
  /// a long focused session might be 2.0. Backward-compatible: existing
  /// stored records without this key are read as 1.0.
  final double weight;

  CheckIn({
    String? id,
    required this.practiceId,
    required this.goalId,
    required this.note,
    required this.effortLevel,
    this.durationMinutes,
    DateTime? timestamp,
    this.weight = 1.0,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  CheckIn copyWith({
    String? id,
    String? practiceId,
    String? goalId,
    String? note,
    int? effortLevel,
    Object? durationMinutes = _sentinel,
    DateTime? timestamp,
    double? weight,
  }) {
    return CheckIn(
      id: id ?? this.id,
      practiceId: practiceId ?? this.practiceId,
      goalId: goalId ?? this.goalId,
      note: note ?? this.note,
      effortLevel: effortLevel ?? this.effortLevel,
      durationMinutes: durationMinutes == _sentinel
          ? this.durationMinutes
          : durationMinutes as int?,
      timestamp: timestamp ?? this.timestamp,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'practiceId': practiceId,
      'goalId': goalId,
      'note': note,
      'effortLevel': effortLevel,
      'durationMinutes': durationMinutes,
      'timestamp': timestamp.toIso8601String(),
      'weight': weight,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'] as String,
      practiceId: map['practiceId'] as String,
      goalId: map['goalId'] as String,
      note: map['note'] as String,
      effortLevel: map['effortLevel'] as int,
      durationMinutes: map['durationMinutes'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      // Backward-compatible default: existing records without 'weight' → 1.0
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  String toString() {
    return 'CheckIn(id: $id, practiceId: $practiceId, goalId: $goalId, '
        'note: $note, effortLevel: $effortLevel, '
        'durationMinutes: $durationMinutes, weight: $weight, '
        'timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckIn && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
