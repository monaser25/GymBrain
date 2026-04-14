import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  void _selectLanguage(BuildContext context, String langCode) {
    GymDatabase().setLanguageCode(langCode);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We cannot use AppLocalizations until we return a locale aware widget tree or just hardcode the text 
    // for language selection to show native names.
    // It's best if the language cards use the native scripts natively.

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated App Logo
              Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOutBack,
                  builder: (context, double val, child) {
                    return Transform.scale(
                      scale: val,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              Text(
                "Select Language\nاختر اللغة",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF39FF14).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),

              // English Card
              LanguageCard(
                languageName: "English",
                subtitle: "Hello, Welcome to Gym Brain",
                flag: "🇺🇸\n🇬🇧",
                onTap: () => _selectLanguage(context, 'en'),
              ),
              
              const SizedBox(height: 24),

              // Arabic Card
              LanguageCard(
                languageName: "العربية",
                subtitle: "أهلاً بك في جيم برين",
                flag: "🇸🇦\n🇪🇬",
                onTap: () => _selectLanguage(context, 'ar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageCard extends StatelessWidget {
  final String languageName;
  final String subtitle;
  final String flag;
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.languageName,
    required this.subtitle,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF39FF14).withValues(alpha: 0.2),
        highlightColor: const Color(0xFF39FF14).withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                flag.split('\n')[0], // Just display first flag for simplicity
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF39FF14),
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
