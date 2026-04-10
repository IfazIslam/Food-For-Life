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
    
    try {
      // Prevent duplicate requests
      final existingChat = await FirebaseFirestore.instance.collection('chats')
          .where('feedIdRequested', isEqualTo: feed.feedId)
          .where('participants', arrayContains: currentUser.uid)
          .get();

      if (existingChat.docs.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have already requested this. Check your chats!')));
        }
        return;
      }

      final chatId = const Uuid().v4();
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'participants': [currentUser.uid, feed.donorUid],
        'feedIdRequested': feed.feedId,
        'accepted': false,
        'completed': false,
        'status': 'pending',
        'initiatorUid': currentUser.uid,
        'messages': [
          {
            'senderId': currentUser.uid,
            'text': "I want this",
            'timestamp': Timestamp.now(),
          }
        ]
      });
      // Send notification
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
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
          IconButton(
            icon: const Icon(Icons.notifications_rounded, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
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
              return _FeedCard(feed: feeds[i], onRequest: (f) => _requestFood(context, f, ref))
                  .animate().fade().slideY(begin: 0.2);
            },
          );
        },
      ),
    );
  }
}

class _FeedCard extends StatefulWidget {
  final FeedModel feed;
  final Function(FeedModel) onRequest;

  const _FeedCard({required this.feed, required this.onRequest});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final expiryTime = widget.feed.postedAt.add(Duration(hours: widget.feed.timeDurationHours));
    final durationLeft = expiryTime.difference(DateTime.now());
    final isExpired = durationLeft.isNegative;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.washedOutGreen,
              backgroundImage: widget.feed.donorProfileImage.isNotEmpty ? NetworkImage(widget.feed.donorProfileImage) : null,
              child: widget.feed.donorProfileImage.isEmpty ? const Icon(Icons.person, color: AppTheme.primaryGreen) : null,
            ),
            title: Text(widget.feed.donorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(timeago.format(widget.feed.postedAt)),
            trailing: Text(widget.feed.tag, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
          if (widget.feed.imageUrl.isNotEmpty)
            Image.network(
              widget.feed.imageUrl, 
              height: 250, 
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 250,
                  color: AppTheme.washedOutGreen.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stack) => Container(
                height: 250,
                color: AppTheme.washedOutGreen.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: AppTheme.primaryGreen, size: 40),
                      SizedBox(height: 8),
                      Text('Image unavailable', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.feed.foodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isExpired ? "Expired" : "${durationLeft.inHours}h ${durationLeft.inMinutes.remainder(60)}m left",
                        style: TextStyle(color: isExpired ? Colors.red : AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.feed.description,
                  maxLines: _isExpanded ? null : 2,
                  overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(_isExpanded ? "Collapse" : "Expand Description", style: const TextStyle(color: AppTheme.primaryGreen)),
                    ),
                    const Spacer(),
                    if (_isExpanded && !isExpired)
                      ElevatedButton(
                        onPressed: () => widget.onRequest(widget.feed),
                        child: const Text("Request Food"),
                      ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
