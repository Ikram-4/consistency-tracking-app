import 'dart:math' show exp, sqrt;

/// Lightweight model that computes a confidence score for a habit-completion
/// projection, combining two orthogonal signals:
///
/// **Volume score** — how many calendar days of check-in history exist.
/// More history = more trustworthy trend, saturating at large values:
///   `volumeScore = (1 − exp(−historyDays / 20)).clamp(0, 1)`
///
/// **Variance score** — how stable daily consistency values have been.
/// Computed via the coefficient of variation (CV = σ / (μ + ε)), inverted
/// so that a perfectly flat consistency series scores 1.0 and a wildly
/// erratic one scores near 0:
///   `varianceScore = (1 − CV).clamp(0, 1)`
///
/// The two scores are combined with equal weight:
///   `confidence = volumeScore * 0.5 + varianceScore * 0.5`
class ProjectionConfidence {
  /// Small epsilon used when dividing by mean consistency to avoid
  /// division-by-zero in the coefficient-of-variation calculation.
  static const double _epsilon = 0.0001;

  /// Smoothing window (in days) for the volume score exponential saturation.
  static const double _volumeHalfLife = 20.0;

  const ProjectionConfidence._();

  // ---------------------------------------------------------------------------
  // Component scores
  // ---------------------------------------------------------------------------

  /// Score in [0, 1] reflecting how many days of check-in history exist.
  ///
  /// Saturates with diminishing returns:
  ///   `volumeScore = (1 − exp(−historyDays / 20)).clamp(0, 1)`
  ///
  /// - historyDays = 0  → 0.00
  /// - historyDays = 20 → ≈ 0.63
  /// - historyDays = 60 → ≈ 0.95
  static double volumeScore(int historyDays) {
    if (historyDays <= 0) return 0.0;
    return (1.0 - exp(-historyDays / _volumeHalfLife)).clamp(0.0, 1.0);
  }

  /// Score in [0, 1] reflecting how stable (low-variance) the daily
  /// consistency series has been.
  ///
  /// Computes the population standard deviation and normalises it against
  /// the mean via the coefficient of variation (CV), then inverts:
  ///   `CV       = stdDev / (mean + epsilon)`
  ///   `score    = (1 − CV).clamp(0, 1)`
  ///
  /// - A perfectly flat series (e.g. 1,1,1,1,1) → CV ≈ 0 → score ≈ 1.0
  /// - An all-zeros series → mean ≈ 0, CV ≈ 0 → score ≈ 1.0 (but volume
  ///   score will dominate and pull combined confidence low).
  /// - A highly erratic series (e.g. 0,3,0,3,0) → high CV → score near 0.
  static double varianceScore(List<double> dailyConsistencies) {
    if (dailyConsistencies.isEmpty) return 0.0;

    final n = dailyConsistencies.length;
    final mean = dailyConsistencies.reduce((a, b) => a + b) / n;
    final variance = dailyConsistencies
            .map((c) => (c - mean) * (c - mean))
            .reduce((a, b) => a + b) /
        n;
    final stdDev = sqrt(variance);

    final cv = stdDev / (mean + _epsilon);
    return (1.0 - cv).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Combined score + label
  // ---------------------------------------------------------------------------

  /// Combines [volumeScore] and [varianceScore] with equal weight into a
  /// single confidence value in [0, 1].
  static double confidenceScore(double volumeScore, double varianceScore) =>
      (volumeScore * 0.5 + varianceScore * 0.5).clamp(0.0, 1.0);

  /// Maps a combined confidence score to a human-readable label.
  ///
  /// - score >= 0.7 → 'High'
  /// - score >= 0.4 → 'Medium'
  /// - score <  0.4 → 'Low'
  static String confidenceLabel(double score) {
    if (score >= 0.7) return 'High';
    if (score >= 0.4) return 'Medium';
    return 'Low';
  }
}

/// The result returned by [HabitRepository.projectedCompletion].
///
/// Bundles the optional projected day index with a pre-computed confidence
/// score and label so the UI can display both in one call.
class ProjectionResult {
  /// Projected day index at which accumulated progress reaches the goal,
  /// or `null` if not reachable within the projection horizon.
  final int? projectedDay;

  /// Combined confidence score in [0, 1].
  final double confidence;

  /// Human-readable confidence label: 'High', 'Medium', or 'Low'.
  final String label;

  const ProjectionResult({
    required this.projectedDay,
    required this.confidence,
    required this.label,
  });

  @override
  String toString() =>
      'ProjectionResult(projectedDay: $projectedDay, '
      'confidence: ${confidence.toStringAsFixed(3)}, label: $label)';
}
