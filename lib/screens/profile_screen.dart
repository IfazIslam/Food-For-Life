import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/feed_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/imgbb_service.dart';
import '../widgets/custom_image.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPfp = false;

  Future<void> _updateProfileImage(UserModel user) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingPfp = true);
    try {
      final String? url = await ImgBBService.uploadImage(File(pickedFile.path));
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profileImageUrl': url});
        final feedsQuery = await FirebaseFirestore.instance.collection('feeds').where('donorUid', isEqualTo: user.uid).get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in feedsQuery.docs) {
          batch.update(doc.reference, {'donorProfileImage': url});
        }
        await batch.commit();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image. Try a smaller file.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _isUploadingPfp = false);
  }

  Future<void> _editBio(UserModel user) async {
    final ctrl = TextEditingController(text: user.bio);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  const Text('Edit Bio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tell people about yourself...',
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'bio': ctrl.text.trim()});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost(String feedId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this donation post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('feeds').doc(feedId).delete();
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('notifications').doc().set({
          'id': const Uuid().v4(),
          'targetUid': currentUser.uid,
          'title': 'Feed Deleted',
          'body': 'You deleted a donation post',
          'type': 'system',
          'isRead': false,
          'timestamp': Timestamp.now(),
        });
      }
    }
  }

  Future<void> _editPost(FeedModel post) async {
    final nameCtrl = TextEditingController(text: post.foodName);
    final descCtrl = TextEditingController(text: post.description);
    final tagCtrl = TextEditingController(text: post.tag);
    double duration = post.timeDurationHours.toDouble();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    const Text('Edit Donation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: _sheetInput('Food Name', Icons.fastfood_rounded),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _sheetInput('Description', Icons.description_rounded),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagCtrl,
                  decoration: _sheetInput('Tag (e.g. #rice)', Icons.tag_rounded),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edible Duration: ${duration.toInt()} hours',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
                ),
                Slider(
                  value: duration,
                  min: 1,
                  max: 74,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (v) => setSheetState(() => duration = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      String tag = tagCtrl.text.trim();
                      if (tag.isNotEmpty && !tag.startsWith('#')) tag = '#$tag';
                      await FirebaseFirestore.instance.collection('feeds').doc(post.feedId).update({
                        'foodName': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'tag': tag.toLowerCase(),
                        'timeDurationHours': duration.toInt(),
                      });
                      if (context.mounted) Navigator.pop(context);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donation updated!')));
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _sheetInput(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
    filled: true,
    fillColor: const Color(0xFFF5F7F5),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
  @override
  Widget build(BuildContext context) {
    final AsyncValue<UserModel?> userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("User not found"));
          return CustomScrollView(
            slivers: [
              // ── Gradient Banner + Avatar Card ────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: const Color(0xFF2E7D52),
                title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                centerTitle: true,
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
                            GestureDetector(
                              onTap: () => _updateProfileImage(user),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Colors.amber, Color(0xFF57AB74)],
                                      ),
                                    ),
                                    child: CustomAvatar(
                                      imageUrl: user.profileImageUrl,
                                      radius: 46,
                                      placeholderIcon: Icons.person,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2, right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGreen, size: 14),
                                    ),
                                  ),
                                ],
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
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _editBio(user),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.washedOutGreen.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_rounded, color: AppTheme.primaryGreen, size: 14),
                                  SizedBox(width: 4),
                                  Text('Edit', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.bio.isEmpty ? 'No bio yet. Tap Edit to add one.' : user.bio,
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

              // ── Donations Header ────────────────────────────────
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
                      const Text('My Donations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),

              // ── Donation Grid ────────────────────────────────────
              _DonationGrid(uid: user.uid, onDelete: _deletePost, onEdit: _editPost),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, s) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _divider() => Container(width: 1, height: 40, color: Colors.grey.shade200);
}

// ── Stat Pill ────────────────────────────────────────────────────────────────
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

// ── Donation Grid ─────────────────────────────────────────────────────────────
class _DonationGrid extends ConsumerWidget {
  final String uid;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(FeedModel) onEdit;

  const _DonationGrid({required this.uid, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text('No donations yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Tap + to post your first food donation!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs
            .map((d) => FeedModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList()
          ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

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
                return _DonationCard(post: post, onDelete: onDelete, onEdit: onEdit)
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

// ── Donation Card ─────────────────────────────────────────────────────────────
class _DonationCard extends StatelessWidget {
  final FeedModel post;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(FeedModel) onEdit;

  const _DonationCard({required this.post, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isExpired = DateTime.now().isAfter(post.postedAt.add(Duration(hours: post.timeDurationHours)));

    return GestureDetector(
      onTap: () => onEdit(post),
      onLongPress: () => onDelete(post.feedId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: CustomNetworkImage(
                      imageUrl: post.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Expired overlay
                  if (isExpired)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Container(
                        color: Colors.black45,
                        child: const Center(child: Text('EXPIRED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13))),
                      ),
                    ),
                  // Delete button
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => onDelete(post.feedId),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Tag chip
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
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 11, color: isExpired ? Colors.red : AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        isExpired ? 'Expired' : '${post.timeDurationHours}h window',
                        style: TextStyle(fontSize: 11, color: isExpired ? Colors.red : AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
