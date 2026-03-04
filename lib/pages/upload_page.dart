import 'package:flutter/material.dart';
import '../theme.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  double _expirationHours = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate Food'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Photo Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.offGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.offGreen, width: 2, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.add_a_photo_outlined, size: 48, color: AppTheme.offGreen),
                   SizedBox(height: 8),
                   Text('Tap to add photo', style: TextStyle(color: AppTheme.offGreen)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Food Details
            const TextField(
              decoration: InputDecoration(
                hintText: 'What are you donating?',
                prefixIcon: Icon(Icons.fastfood_outlined, color: AppTheme.offGreen),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            const TextField(
              decoration: InputDecoration(
                hintText: 'Add description (e.g. 5 portions, contains nuts)',
                prefixIcon: Icon(Icons.description_outlined, color: AppTheme.offGreen),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Expiration Slider
            Text(
              'Expires in: ${_expirationHours.toInt()} hours',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.offGreen),
            ),
            Slider(
              value: _expirationHours,
              min: 1,
              max: 48,
              divisions: 47,
              activeColor: AppTheme.offOrange,
              inactiveColor: AppTheme.offGreen.withOpacity(0.3),
              onChanged: (value) {
                setState(() {
                  _expirationHours = value;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // Submit Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Food post uploaded successfully!')),
                );
              },
              child: const Text('Post Donation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
