import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'user_details_screen.dart';

class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final allUsers = snapshot.data!.docs
              .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()
            ..sort((a, b) => b.impactPoints.compareTo(a.impactPoints));

          final topTen = allUsers.take(10).toList();
          int currentUserRank = -1;
          if (currentUser != null) {
            currentUserRank = allUsers.indexWhere((u) => u.uid == currentUser.uid) + 1;
          }
          final showCurrentUserSeparator = currentUser != null && currentUserRank > 10;

          return CustomScrollView(
            slivers: [
              // ── Hero Header ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: const Color(0xFF2E7D52),
                title: const Text('🏆 Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E3B), Color(0xFF57AB74), Color(0xFF9ED4B4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 56), // leave space for pinned title
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 44),
                            const SizedBox(height: 6),
                            const Text(
                              'Global Impact',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Top food donors in your community',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            if (currentUser != null && currentUserRank > 0) ...[  
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'Your rank: #$currentUserRank  •  ${currentUser.impactPoints} pts',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Podium Top 3 ────────────────────────────────────
              if (topTen.length >= 3)
                SliverToBoxAdapter(
                  child: _Podium(users: topTen.take(3).toList())
                      .animate().fade(duration: 400.ms).slideY(begin: 0.2),
                ),

              // ── Rank 4–10 List ──────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final start = topTen.length >= 3 ? 3 : 0;
                      final listUsers = topTen.skip(start).toList();

                      if (index < listUsers.length) {
                        return _RankCard(
                          user: listUsers[index],
                          rank: start + index + 1,
                          isCurrentUser: currentUser?.uid == listUsers[index].uid,
                        )
                            .animate(delay: (index * 60).ms)
                            .fade(duration: 350.ms)
                            .slideX(begin: 0.2);
                      } else if (showCurrentUserSeparator) {
                        if (index == listUsers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Expanded(child: Divider(color: AppTheme.washedOutGreen, thickness: 2)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Your Position', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: AppTheme.washedOutGreen, thickness: 2)),
                            ]),
                          );
                        } else {
                          return _RankCard(user: currentUser!, rank: currentUserRank, isCurrentUser: true);
                        }
                      }
                      return null;
                    },
                    childCount: topTen.skip(topTen.length >= 3 ? 3 : 0).length + (showCurrentUserSeparator ? 2 : 0),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

// ── Podium Widget ────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<UserModel> users; // exactly 3 users: [1st, 2nd, 3rd]

  const _Podium({required this.users});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(child: _PodiumColumn(user: users[1], rank: 2, height: 90, color: const Color(0xFFB0BEC5))),
          const SizedBox(width: 8),
          // 1st place
          Expanded(child: _PodiumColumn(user: users[0], rank: 1, height: 120, color: Colors.amber)),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(child: _PodiumColumn(user: users[2], rank: 3, height: 70, color: const Color(0xFFCD7F32))),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final UserModel user;
  final int rank;
  final double height;
  final Color color;

  const _PodiumColumn({required this.user, required this.rank, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsScreen(user: user))),
      child: Column(
        children: [
          // Crown for 1st
          if (rank == 1)
            const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: rank == 1 ? 36 : 28,
                backgroundColor: color.withOpacity(0.3),
                backgroundImage: user.profileImageUrl.isNotEmpty ? NetworkImage(user.profileImageUrl) : null,
                child: user.profileImageUrl.isEmpty
                    ? Icon(Icons.person, color: color, size: rank == 1 ? 36 : 28)
                    : null,
              ),
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: Center(
                  child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(user.name.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          Text('${user.impactPoints} pts', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          // Podium block
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rank Card (4th+) ─────────────────────────────────────────────────────────
class _RankCard extends StatelessWidget {
  final UserModel user;
  final int rank;
  final bool isCurrentUser;

  const _RankCard({required this.user, required this.rank, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsScreen(user: user))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isCurrentUser
              ? Border.all(color: AppTheme.primaryGreen, width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.washedOutGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('#$rank', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.washedOutGreen,
              backgroundImage: user.profileImageUrl.isNotEmpty ? NetworkImage(user.profileImageUrl) : null,
              child: user.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: AppTheme.primaryGreen)
                  : null,
            ),
            const SizedBox(width: 12),
            // Name & username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(20)),
                          child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text('@${user.username}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${user.impactPoints}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const Text('points', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
