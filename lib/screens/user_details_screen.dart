import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../models/feed_model.dart';
import '../theme/app_theme.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header with Avatar ────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D52),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient cover
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E3B), Color(0xFF57AB74)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(top: -30, right: -40, child: _glowCircle(160, Colors.white.withOpacity(0.06))),
                  Positioned(bottom: 40, left: -50, child: _glowCircle(140, Colors.white.withOpacity(0.06))),
                  // Avatar + name centered
                  Positioned(
                    bottom: 0,
                    left: 0, right: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Color(0xFF57AB74)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white,
                            backgroundImage: user.profileImageUrl.isNotEmpty ? NetworkImage(user.profileImageUrl) : null,
                            child: user.profileImageUrl.isEmpty ? const Icon(Icons.person, size: 46, color: AppTheme.primaryGreen) : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('@${user.username}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats Row ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatPill(icon: Icons.star_rounded, label: 'Impact Points', value: '${user.impactPoints}', color: Colors.amber),
                  _divider(),
                  _StatPill(icon: Icons.location_on_rounded, label: 'Location', value: user.addressState, color: AppTheme.primaryGreen),
                  _divider(),
                  _StatPill(icon: Icons.person_rounded, label: 'Gender', value: user.gender, color: Colors.blueAccent),
                ],
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.2),
          ),

          // ── Bio Card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_quote_rounded, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 6),
                      const Text('About Me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.bio.isEmpty ? 'No bio provided.' : user.bio,
                    style: TextStyle(
                      color: user.bio.isEmpty ? Colors.grey : AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: user.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.2),
          ),

          // ── Active Donations Header ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 20,
                    decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Active Donations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),

          // ── Donation Grid ────────────────────────────────────
          _DonationGrid(uid: user.uid),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _divider() => Container(width: 1, height: 40, color: Colors.grey.shade200);
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}

class _DonationGrid extends StatelessWidget {
  final String uid;

  const _DonationGrid({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('feeds').where('donorUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}")));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.fastfood_outlined, size: 48, color: AppTheme.washedOutGreen),
                  SizedBox(height: 12),
                  Text('No active donations', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs
            .map((d) => FeedModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .where((p) => !DateTime.now().isAfter(p.postedAt.add(Duration(hours: p.timeDurationHours)))) // Only show active
            .toList()
          ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

        if (posts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No active donations')),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                return _DonationCard(post: post)
                    .animate(delay: (index * 50).ms)
                    .fade(duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95));
              },
              childCount: posts.length,
            ),
          ),
        );
      },
    );
  }
}

class _DonationCard extends StatelessWidget {
  final FeedModel post;

  const _DonationCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: post.imageUrl.isNotEmpty
                      ? Image.network(
                          post.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.washedOutGreen,
                            child: const Center(child: Icon(Icons.fastfood_rounded, color: AppTheme.primaryGreen, size: 36)),
                          ),
                        )
                      : Container(
                          color: AppTheme.washedOutGreen,
                          child: const Center(child: Icon(Icons.fastfood_rounded, color: AppTheme.primaryGreen, size: 36)),
                        ),
                ),
                if (post.tag.isNotEmpty)
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(post.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    Text('${post.timeDurationHours}h window', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
