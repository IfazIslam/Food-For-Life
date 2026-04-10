import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedState = 'Dhaka';
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bdStates = [
    'Dhaka', 'Chittagong', 'Rajshahi', 'Khulna', 
    'Barisal', 'Sylhet', 'Rangpur', 'Mymensingh'
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Check if username exists
      final usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _usernameCtrl.text.trim())
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username already taken")));
        return;
      }

      final creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (creds.user != null) {
        UserModel user = UserModel(
          uid: creds.user!.uid,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          gender: _selectedGender,
          username: _usernameCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          addressState: _selectedState,
        );

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(user.toMap());
        if (mounted) context.go('/main');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: AppTheme.washedOutGreen,),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Join us to reduce waste!", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.contains('@') ? null : 'Invalid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username (unique)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGender = v!),
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  items: _bdStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedState = v!),
                  decoration: const InputDecoration(labelText: 'State (Division)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioCtrl,
                  decoration: const InputDecoration(labelText: 'Bio / Short Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v!.length >= 6 ? null : 'Min 6 chars',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassCtrl,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Register'),
                      ).animate().fade(duration: 500.ms).slideY(begin: 0.5),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text("Already have an account? Login", style: TextStyle(color: AppTheme.primaryGreen)),
                )
              ],
            ).animate().fade(duration: 400.ms),
          ),
        ),
      ),
    );
  }
}
