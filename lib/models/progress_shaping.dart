import 'dart:math' show exp;

/// Maps raw linear progress fraction (0.0–1.0+) to a perceived
/// progress fraction using a logistic S-curve: slow start, faster
/// middle, slow finish near completion. Purely cosmetic — does not
/// change what counts as "done".
double shapeProgress(double rawFraction, {double steepness = 8.0}) {
  final x = rawFraction.clamp(0.0, 1.0);
  double logistic(double v) => 1 / (1 + exp(-steepness * (v - 0.5)));
  final f0 = logistic(0.0);
  final f1 = logistic(1.0);
  final raw = logistic(x);
  return ((raw - f0) / (f1 - f0)).clamp(0.0, 1.0);
}
