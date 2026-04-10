import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierCtrl = TextEditingController(); // Username or Email
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_identifierCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      String email = _identifierCtrl.text.trim();

      // If it's not an email, assume it's username and fetch the email from Firestore
      if (!email.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          throw Exception("Username not found");
        }
        email = query.docs.first.data()['email'];
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passCtrl.text,
      );

      if (mounted) context.go('/main');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.washedOutGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 80)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                const SizedBox(height: 32),
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fade().slideY(begin: -0.2),
                const SizedBox(height: 32),
                TextField(
                  controller: _identifierCtrl,
                  decoration: const InputDecoration(labelText: 'Email or Username'),
                ).animate().fade(delay: 100.ms).slideX(begin: -0.2),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ).animate().fade(delay: 200.ms).slideX(begin: -0.2),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ).animate().fade(delay: 300.ms).scale(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text("Don't have an account? Register", style: TextStyle(color: AppTheme.primaryGreen)),
                ).animate().fade(delay: 400.ms)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
