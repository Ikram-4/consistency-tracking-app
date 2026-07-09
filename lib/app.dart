import 'package:flutter/material.dart';
import 'package:phantom/theme/app_theme.dart';
import 'package:phantom/screens/home_screen.dart';

/// Root application widget for Phantom.
///
/// Configures the [MaterialApp] with the app's dark theme
/// and sets [HomeScreen] as the initial route.
class PhantomApp extends StatelessWidget {
  const PhantomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phantom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
