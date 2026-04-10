import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Artificial delay for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      ref.read(firstTimeProvider.notifier).update(true);
      if(mounted) context.go('/onboarding');
    } else {
      ref.read(firstTimeProvider.notifier).update(false);
      if(mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 100,
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).then().shake(hz: 4, curve: Curves.easeInOut),
            const SizedBox(height: 20),
            Text(
              'Food For Life',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade(duration: 800.ms).slideY(begin: 0.5, end: 0),
          ],
        ),
      ),
    );
  }
}
