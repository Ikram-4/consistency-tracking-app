import 'package:flutter/foundation.dart';
import 'package:phantom/models/weekly_review.dart';
import 'package:phantom/repositories/weekly_review_repository.dart';

/// Manages weekly review state and business logic.
///
/// Handles CRUD operations for weekly reviews and provides
/// convenience methods for finding reviews by week.
class WeeklyReviewProvider extends ChangeNotifier {
  final WeeklyReviewRepository _reviewRepo;

  List<WeeklyReview> _reviews = [];

  /// Creates a [WeeklyReviewProvider] backed by the given repository.
  WeeklyReviewProvider(this._reviewRepo) {
    loadReviews();
  }

  /// All weekly reviews, most recent first.
  List<WeeklyReview> get reviews => List.unmodifiable(_reviews);

  /// Loads all reviews from the repository.
  void loadReviews() {
    _reviews = _reviewRepo.getAll()
      ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
    notifyListeners();
  }

  /// Saves a new or updated weekly review.
  Future<void> saveReview(WeeklyReview review) async {
    await _reviewRepo.save(review);
    loadReviews();
  }

  /// Deletes a weekly review by ID.
  Future<void> deleteReview(String id) async {
    await _reviewRepo.delete(id);
    loadReviews();
  }

  /// Returns the review for a specific week, if it exists.
  WeeklyReview? getByWeekStart(DateTime weekStart) {
    return _reviewRepo.getByWeekStart(weekStart);
  }

  /// Returns the most recent weekly review, if any exist.
  WeeklyReview? getLatest() {
    return _reviewRepo.getLatest();
  }

  /// Returns a review by ID.
  WeeklyReview? getById(String id) {
    try {
      return _reviews.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
