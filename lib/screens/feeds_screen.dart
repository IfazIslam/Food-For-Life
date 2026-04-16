import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'upload_feed_screen.dart';
import 'notifications_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../widgets/custom_image.dart';
import '../widgets/feed_details_modal.dart';
import '../providers/notification_provider.dart';

class FeedsScreen extends ConsumerStatefulWidget {
  const FeedsScreen({super.key});

  @override
  ConsumerState<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends ConsumerState<FeedsScreen> {
  String _searchTag = "";
  final _searchCtrl = TextEditingController();

  Stream<List<FeedModel>> _getFeedsStream(String userState) {
    Query query = FirebaseFirestore.instance
        .collection('feeds')
        .where('donorState', isEqualTo: userState);
        
    return query.snapshots().map((snapshot) {
      final feeds = snapshot.docs.map((doc) => FeedModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      feeds.sort((a, b) => b.postedAt.compareTo(a.postedAt));
      
      if (_searchTag.isNotEmpty) {
        return feeds.where((f) => f.tag.toLowerCase().contains(_searchTag.toLowerCase())).toList();
      }
      return feeds;
    });
  }

  void _requestFood(BuildContext context, FeedModel feed, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;
    
    if (currentUser.uid == feed.donorUid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot request your own food!")));
      }
      return;
    }
    
    try {
      // 1. Check for any existing chat between these two users
      final chatQuery = await FirebaseFirestore.instance.collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();
          
      DocumentSnapshot? existingChatDoc;
      for (var doc in chatQuery.docs) {
        List<dynamic> parts = doc.data()['participants'] ?? [];
        if (parts.contains(feed.donorUid)) {
          existingChatDoc = doc;
          break;
        }
      }

      if (existingChatDoc != null) {
        final chatId = existingChatDoc.id;
        final data = existingChatDoc.data() as Map<String, dynamic>;
        
        // 2. If it's the exact same feed again, prevent duplicate
        if (data['feedIdRequested'] == feed.feedId && data['completed'] == false) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have already requested this. Check your chats!')));
          }
          return;
        }

        // 3. Reuse existing chat: update transaction fields and add message
        final newMessage = {
          'senderId': currentUser.uid,
          'text': "I want this (${feed.foodName})",
          'timestamp': Timestamp.now(),
        };

        await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
          'feedIdRequested': feed.feedId,
          'accepted': false,
          'completed': false,
          'initiatorUid': currentUser.uid, // Mark current requester as initiator of this request
          'messages': FieldValue.arrayUnion([newMessage]),
        });

        // 4. Send notification
        await FirebaseFirestore.instance.collection('notifications').doc().set({
          'id': const Uuid().v4(),
          'targetUid': feed.donorUid,
          'senderUid': currentUser.uid,
          'chatId': chatId,
          'title': 'New Food Request',
          'body': '${currentUser.name} requested ${feed.foodName}',
          'type': 'request',
          'isRead': false,
          'timestamp': Timestamp.now(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request updated in existing chat!')));
        }
      } else {
        // 5. No existing chat: create new one
        final chatId = const Uuid().v4();
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'participants': [currentUser.uid, feed.donorUid],
          'feedIdRequested': feed.feedId,
          'accepted': false,
          'completed': false,
          'status': 'pending', // New chats start as pending
          'initiatorUid': currentUser.uid,
          'messages': [
            {
              'senderId': currentUser.uid,
              'text': "I want this (${feed.foodName})",
              'timestamp': Timestamp.now(),
            }
          ]
        });

        await FirebaseFirestore.instance.collection('notifications').doc().set({
          'id': const Uuid().v4(),
          'targetUid': feed.donorUid,
          'senderUid': currentUser.uid,
          'chatId': chatId,
          'title': 'New Food Request',
          'body': '${currentUser.name} requested ${feed.foodName}',
          'type': 'request',
          'isRead': false,
          'timestamp': Timestamp.now(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent and new chat created!')));
        }
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 28),
            const SizedBox(width: 8),
            Text("Food for Life", style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryGreen, fontWeight: FontWeight.bold
            )),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
              return Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.red,
                offset: const Offset(-4, 4),
                child: IconButton(
                  icon: const Icon(Icons.notifications_rounded, size: 28),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, size: 30),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadFeedScreen())),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchTag = v),
              decoration: InputDecoration(
                hintText: "Search by tags (e.g. #burger)",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchTag = "");
                  },
                ),
                contentPadding: const EdgeInsets.all(0),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<FeedModel>>(
        stream: _getFeedsStream(user.addressState),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          if (snapshot.hasError) return Center(child: Text("Error fetching feeds. Exception: \${snapshot.error}", textAlign: TextAlign.center));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No feeds available in your state."));
          }

          final feeds = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: feeds.length,
            itemBuilder: (context, i) {
              return _FeedCard(
                feed: feeds[i], 
                currentUid: user.uid,
                onRequest: (f) => _requestFood(context, f, ref),
              ).animate().fade().slideY(begin: 0.2);
            },
          );
        },
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedModel feed;
  final String currentUid;
  final Function(FeedModel) onRequest;

  const _FeedCard({required this.feed, required this.currentUid, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final expiryTime = feed.postedAt.add(Duration(hours: feed.timeDurationHours));
    final durationLeft = expiryTime.difference(DateTime.now());
    final isExpired = durationLeft.isNegative;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => FeedDetailsModal.show(context, feed, currentUid, onRequest),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: CustomAvatar(imageUrl: feed.donorProfileImage, radius: 20),
              title: Text(feed.donorName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(timeago.format(feed.postedAt)),
              trailing: Text(feed.tag, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ),
            CustomNetworkImage(
              imageUrl: feed.imageUrl,
              height: 250,
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          feed.foodName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.red.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isExpired ? "Expired" : "${durationLeft.inHours}h ${durationLeft.inMinutes.remainder(60)}m left",
                          style: TextStyle(
                            color: isExpired ? Colors.red : AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => FeedDetailsModal.show(context, feed, currentUid, onRequest),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text("View Details", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => FeedDetailsModal.show(context, feed, currentUid, onRequest),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (feed.donorUid == currentUid || isExpired) ? Colors.grey : AppTheme.primaryGreen,
                        ),
                        child: Text(feed.donorUid == currentUid ? "My Post" : "Request Food"),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
