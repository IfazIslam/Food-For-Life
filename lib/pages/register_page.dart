import 'package:flutter/material.dart';
import '../theme.dart';
import 'main_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Join the cause today!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.offGreen,
              ),
            ),
            const SizedBox(height: 40),
            
            // Name Field
            const TextField(
              decoration: InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.offGreen),
              ),
            ),
            const SizedBox(height: 16),
            
            // Email Field
            const TextField(
              decoration: InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.offGreen),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // Password Field
            const TextField(
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.offGreen),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            // Confirm Password Field
            const TextField(
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.offGreen),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            
            // Register Button
            ElevatedButton(
              onPressed: () {
                // Navigate to main page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainPage()),
                  (route) => false,
                );
              },
              child: const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
