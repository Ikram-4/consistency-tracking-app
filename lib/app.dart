import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phantom/theme/app_theme.dart';
import 'package:phantom/screens/home_screen.dart';
import 'package:phantom/models/celebration_event.dart';
import 'package:phantom/services/celebration_controller.dart';
import 'package:phantom/widgets/celebration_overlay.dart';

/// Root application widget for Phantom.
///
/// Configures the [MaterialApp] with the app's dark theme,
/// sets [HomeScreen] as the initial route, and wraps it in a
/// celebration manager to display overlays globally.
class PhantomApp extends StatelessWidget {
  const PhantomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phantom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      builder: (context, child) {
        return CelebrationWrapper(child: child!);
      },
    );
  }
}

/// A wrapper widget that listens to global celebration events
/// and overlays the celebration UI on top of the entire app.
class CelebrationWrapper extends StatefulWidget {
  final Widget child;

  const CelebrationWrapper({super.key, required this.child});

  @override
  State<CelebrationWrapper> createState() => _CelebrationWrapperState();
}

class _CelebrationWrapperState extends State<CelebrationWrapper> {
  CelebrationEvent? _activeEvent;
  StreamSubscription<CelebrationEvent?>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = CelebrationController.instance.stream.listen((event) {
      if (mounted) {
        setState(() {
          _activeEvent = event;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Stack(
              children: [
                widget.child,
                if (_activeEvent != null)
                  Positioned.fill(
                    child: CelebrationOverlay(
                      event: _activeEvent!,
                      onDismiss: () {
                        CelebrationController.instance.onDismissed(_activeEvent!.dedupeKey);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
