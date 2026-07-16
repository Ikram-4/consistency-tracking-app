import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/celebration_event.dart';
import '../theme/app_theme.dart';

/// Overlay widget displayed when a celebration event is active.
class CelebrationOverlay extends StatefulWidget {
  final CelebrationEvent event;
  final VoidCallback onDismiss;

  /// Creates a [CelebrationOverlay] with the given event and dismiss callback.
  const CelebrationOverlay({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Confetti runs for 2.0 seconds
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();

    // Scale animation with elastic bounce for the icon/checkmark
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();

    // Heavy haptic feedback on goal complete, lighter for others
    if (widget.event.type == CelebrationType.goalComplete) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _dismiss() {
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGoalComplete = widget.event.type == CelebrationType.goalComplete;
    final isStreak = widget.event.type == CelebrationType.streakMilestone;

    // Confetti particles: gold for goal complete, brand-colored matching desaturated palette otherwise
    final List<Color> confettiColors = isGoalComplete
        ? [
            const Color(0xFFD4AF37), // Metallic Gold
            const Color(0xFFF3E5AB), // Soft Gold
            const Color(0xFFC5A059), // Muted Brass
          ]
        : [
            theme.colorScheme.primary,
            AppTheme.onTrack,
            theme.colorScheme.secondary,
          ];

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Semi-transparent backdrop fade
          Container(
            color: Colors.black.withOpacity(0.7),
          ),
          
          // Confetti particle system spraying down from top-center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Downwards
              maxBlastForce: 15,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: isGoalComplete ? 35 : 15,
              gravity: 0.25,
              shouldLoop: false,
              colors: confettiColors,
            ),
          ),

          // Central card containing message
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: min(MediaQuery.of(context).size.width * 0.8, 320.0),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGoalComplete
                      ? const Color(0xFFD4AF37).withOpacity(0.5)
                      : theme.colorScheme.outline,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isGoalComplete
                          ? const Color(0xFF2B2519)
                          : isStreak
                              ? const Color(0xFF261D1A)
                              : theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isGoalComplete
                            ? const Color(0xFFD4AF37)
                            : isStreak
                                ? AppTheme.behind
                                : theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isGoalComplete
                            ? Icons.emoji_events_rounded
                            : isStreak
                                ? Icons.local_fire_department_rounded
                                : Icons.check_circle_outline_rounded,
                        color: isGoalComplete
                            ? const Color(0xFFD4AF37)
                            : isStreak
                                ? AppTheme.behind
                                : theme.colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    widget.event.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.dataWhite,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    widget.event.subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
