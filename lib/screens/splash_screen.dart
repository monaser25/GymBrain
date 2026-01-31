import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    // Start with logo already visible (matching native splash)
    // Then animate with a subtle pulse effect
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation: Start at 1 (already visible from native splash)
    // Then fade in the text below
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Scale animation: 1.0 -> 1.05 -> 1.0 (subtle pulse effect)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Start animation after a brief delay to ensure native splash has transitioned
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });

    // Navigate after 2 seconds total
    Timer(const Duration(seconds: 2), _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    final isFirstTime = GymDatabase().settingsBox.get(
      'is_first_time',
      defaultValue: true,
    );

    if (isFirstTime == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo - always visible (matches native splash)
            // Only applies scale animation (pulse effect)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/app_icon.png',
                width: 192,
                height: 192,
              ),
            ),
            const SizedBox(height: 24),
            // App Name - fades in after native splash
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'GYM BRAIN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF39FF14),
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.4),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
