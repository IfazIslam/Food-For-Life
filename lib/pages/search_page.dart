import 'package:flutter/material.dart';
import '../theme.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Foods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: 'Search for food, locations, or donors...',
                prefixIcon: Icon(Icons.search, color: AppTheme.offGreen),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Popular Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.offGreen,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildCategoryButton('Bakery'),
                _buildCategoryButton('Vegetables'),
                _buildCategoryButton('Fruits'),
                _buildCategoryButton('Meals'),
                _buildCategoryButton('Canned Goods'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppTheme.offGreen.withOpacity(0.1),
      labelStyle: const TextStyle(color: AppTheme.offGreen, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      onPressed: () {},
    );
  }
}
