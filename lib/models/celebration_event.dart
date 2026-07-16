enum CelebrationType {
  goalComplete,      // Priority 0 (highest)
  streakMilestone,   // Priority 1
  singleMilestone,   // Priority 2 (lowest)
}

/// Model class representing a single trigger for a celebration micro-animation.
class CelebrationEvent {
  final CelebrationType type;
  final String title;
  final String subtitle;
  final String dedupeKey;

  /// Creates a [CelebrationEvent] with the given parameters.
  const CelebrationEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.dedupeKey,
  });

  @override
  String toString() => 'CelebrationEvent(type: $type, title: $title, dedupeKey: $dedupeKey)';
}
