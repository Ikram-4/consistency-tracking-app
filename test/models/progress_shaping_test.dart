import 'package:flutter_test/flutter_test.dart';
import 'package:phantom/models/progress_shaping.dart';

void main() {
  group('shapeProgress S-curve display transform', () {
    test('anchors endpoints correctly: shapeProgress(0.0) == 0.0 and shapeProgress(1.0) == 1.0 exactly', () {
      expect(shapeProgress(0.0), 0.0);
      expect(shapeProgress(1.0), 1.0);
    });

    test('is symmetric: shapeProgress(0.5) is close to 0.5', () {
      expect(shapeProgress(0.5), closeTo(0.5, 1e-9));
    });

    test('is monotonically increasing', () {
      final p3 = shapeProgress(0.3);
      final p5 = shapeProgress(0.5);
      final p7 = shapeProgress(0.7);

      expect(p3, lessThan(p5));
      expect(p5, lessThan(p7));

      // Test a fine grid
      var prev = 0.0;
      for (var i = 1; i <= 100; i++) {
        final current = shapeProgress(i / 100.0);
        expect(current, greaterThanOrEqualTo(prev),
            reason: 'Failed monotonicity at step $i/100');
        prev = current;
      }
    });

    test('is slower near 0 and 1 than near 0.5 (S-curve validation)', () {
      // S-curve implies the slope/derivative is highest at the midpoint (0.5).
      // Verify delta around midpoint is larger than delta near 0.
      final midDelta = shapeProgress(0.5) - shapeProgress(0.4);
      final earlyDelta = shapeProgress(0.1) - shapeProgress(0.0);
      expect(midDelta, greaterThan(earlyDelta),
          reason: 'Midpoint progress delta ($midDelta) should be larger than early progress delta ($earlyDelta)');

      // Verify delta around midpoint is also larger than delta near 1.
      final lateDelta = shapeProgress(1.0) - shapeProgress(0.9);
      expect(midDelta, greaterThan(lateDelta),
          reason: 'Midpoint progress delta ($midDelta) should be larger than late progress delta ($lateDelta)');
    });

    test('clamps overshoot value above 1.0 to 1.0 exactly', () {
      expect(shapeProgress(1.3), 1.0);
      expect(shapeProgress(2.5), 1.0);
      expect(shapeProgress(100.0), 1.0);
    });

    test('clamps negative value to 0.0 exactly', () {
      expect(shapeProgress(-0.5), 0.0);
      expect(shapeProgress(-10.0), 0.0);
    });
  });
}
