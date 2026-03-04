import 'package:flutter/material.dart';
import '../theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the food feed (local images only)
    final List<Map<String, dynamic>> foodPosts = [
      {
        'title': '5 Pieces of Telapia',
        'distance': '1.2 km away',
        'expiresInHours': 3,
        'imageUrl': 'assets/images/fish.png',
        'posterName': 'Janata Housing',
      },
      {
        'title': 'Chicken Briyani 1kg',
        'distance': '2.5 km away',
        'expiresInHours': 1,
        'imageUrl': 'assets/images/briyani.png',
        'posterName': 'Chetona School',
      },
      {
        'title': 'Polao 500gm',
        'distance': '0.8 km away',
        'expiresInHours': 48,
        'imageUrl': 'assets/images/polao.png',
        'posterName': 'Unser Camp',
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: foodPosts.length,
        itemBuilder: (context, index) {
          final post = foodPosts[index];

          // Check if the image path is local or network
          final bool isNetworkImage = post['imageUrl'].toString().startsWith('http');

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Header
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: isNetworkImage
                        ? Image.network(
                      post['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.offGreen.withOpacity(0.2),
                        child: const Icon(Icons.restaurant,
                            size: 50, color: AppTheme.offGreen),
                      ),
                    )
                        : Image.asset(
                      post['imageUrl'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Time Left
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              post['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.offOrange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Expires in ${post['expiresInHours']}h',
                              style: const TextStyle(
                                color: AppTheme.offOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Poster & Distance
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            post['posterName'],
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const Spacer(),
                          const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.offGreen),
                          const SizedBox(width: 4),
                          Text(
                            post['distance'],
                            style: const TextStyle(color: AppTheme.offGreen, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Request Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Request sent for ${post['title']}!')),
                            );
                          },
                          child: const Text('Request this Food'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}