import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/celebration_event.dart';

/// Singleton controller that manages a priority-based queue of celebration events
/// and coordinates showing them one by one.
class CelebrationController {
  CelebrationController._();

  /// The single instance of [CelebrationController].
  static final CelebrationController instance = CelebrationController._();

  final List<CelebrationEvent> _queue = [];
  final Set<String> _shownKeys = {};
  final _controller = StreamController<CelebrationEvent?>.broadcast();

  CelebrationEvent? _currentEvent;

  /// Stream of the active celebration event. Null means no active celebration.
  Stream<CelebrationEvent?> get stream => _controller.stream;

  /// Returns the currently active celebration event.
  CelebrationEvent? get currentEvent => _currentEvent;

  /// Enqueues a list of celebration events.
  ///
  /// Sorts them by priority (ordinal value of type, lowest index is highest priority:
  /// goalComplete = 0, streakMilestone = 1, singleMilestone = 2).
  /// Skips duplicate events using shown keys.
  void enqueue(List<CelebrationEvent> events) {
    if (events.isEmpty) return;

    final newEvents = <CelebrationEvent>[];
    for (final event in events) {
      if (_shownKeys.contains(event.dedupeKey)) {
        debugPrint('Celebration deduped: ${event.dedupeKey}');
        continue;
      }
      newEvents.add(event);
    }

    if (newEvents.isEmpty) return;

    // Sort new events by priority: ordinal of CelebrationType ascending
    newEvents.sort((a, b) => a.type.index.compareTo(b.type.index));

    _queue.addAll(newEvents);
    _processNext();
  }

  /// Called when the active overlay has finished showing and is dismissed.
  void onDismissed(String dedupeKey) {
    _shownKeys.add(dedupeKey);
    _currentEvent = null;
    _controller.add(null);
    
    // Process next item in the queue after a small delay
    Timer(const Duration(milliseconds: 300), _processNext);
  }

  void _processNext() {
    if (_currentEvent != null || _queue.isEmpty) return;

    _currentEvent = _queue.removeAt(0);
    _controller.add(_currentEvent);
  }

  /// Clears the queue and shown keys (e.g. for reset/testing).
  void clear() {
    _queue.clear();
    _shownKeys.clear();
    _currentEvent = null;
    _controller.add(null);
  }
}
