import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Future<void> _markAsRead(String notifId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notifId).update({'isRead': true});
  }

  Future<void> _acceptChat(String chatId, String notifId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({'status': 'accepted'});
    await FirebaseFirestore.instance.collection('notifications').doc(notifId).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted!')));
  }

  Future<void> _declineChat(String chatId, String notifId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
    await FirebaseFirestore.instance.collection('notifications').doc(notifId).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request declined.')));
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Not logged in"));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('targetUid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(context);
              }

              final notifications = snapshot.data!.docs
                  .map((d) => NotificationModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                  .toList();
              notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              return CustomScrollView(
                slivers: [
                  // ── Modern Header ────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 140,
                    pinned: true,
                    backgroundColor: const Color(0xFF2E7D52),
                    title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    centerTitle: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B5E3B), Color(0xFF57AB74)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Icon(Icons.notifications_active_rounded, color: Colors.white24, size: 50),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          final batch = FirebaseFirestore.instance.batch();
                          for (var doc in snapshot.data!.docs) {
                            batch.update(doc.reference, {'isRead': true});
                          }
                          await batch.commit();
                        },
                        child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),

                  // ── Notification List ────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationCard(context, notif)
                              .animate().fade(duration: 300.ms).slideY(begin: 0.1);
                        },
                        childCount: notifications.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, s) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        AppBar(title: const Text('Notifications'), backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No new notifications', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('We\'ll let you know when something happens!', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notif) {
    final isActionable = notif.type == 'request' || notif.type == 'chat_request';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: notif.isRead ? null : Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _markAsRead(notif.id),
            contentPadding: const EdgeInsets.all(16),
            leading: _buildAvatar(notif.senderUid),
            title: Row(
              children: [
                Expanded(child: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 15))),
                if (!notif.isRead)
                   Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(notif.body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Text(timeago.format(notif.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          if (isActionable && notif.chatId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _acceptChat(notif.chatId!, notif.id),
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _declineChat(notif.chatId!, notif.id),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String senderUid) {
    if (senderUid.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.washedOutGreen,
        child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryGreen),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(senderUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade200);
        }
        final u = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF57AB74), Color(0xFF8BC4A2)]),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            backgroundImage: u.profileImageUrl.isNotEmpty ? NetworkImage(u.profileImageUrl) : null,
            child: u.profileImageUrl.isEmpty ? const Icon(Icons.person, color: AppTheme.primaryGreen) : null,
          ),
        );
      },
    );
  }
}
