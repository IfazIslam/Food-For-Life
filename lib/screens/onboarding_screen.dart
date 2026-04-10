import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    ref.read(firstTimeProvider.notifier).update(false);
    if (context.mounted) context.go('/register');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.washedOutGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Dynamic rewritable text
              SizedBox(
                height: 120,
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                  child: AnimatedTextKit(
                    pause: const Duration(milliseconds: 1000),
                    repeatForever: true,
                    animatedTexts: [
                      TypewriterAnimatedText('Welcome to\nFood for Life!'),
                      TypewriterAnimatedText('Share Your\nLeftovers.'),
                      TypewriterAnimatedText('Reduce\nFood Waste.'),
                      TypewriterAnimatedText('Help People\nIn Need.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Join our community dedicated to making sure good food goes to people, not landfills. Together, we can make an impact.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
              ).animate().fade(duration: 1000.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: InkWell(
                  onTap: () => _completeOnboarding(context, ref),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .moveY(begin: -5, end: 5, duration: 1000.ms, curve: Curves.easeInOut)
                    .then()
                    .moveY(begin: 5, end: -5, duration: 1000.ms, curve: Curves.easeInOut),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
