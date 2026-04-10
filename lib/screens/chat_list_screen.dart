import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/custom_image.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _usernameCtrl = TextEditingController();
  String _searchQuery = "";

  Future<void> _startNewChat(UserModel currentUser) async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) return;

    if (username == currentUser.username) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot chat with yourself")));
      return;
    }

    try {
      final query = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: username).limit(1).get();
      if (query.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found")));
        return;
      }
      final otherUser = UserModel.fromMap(query.docs.first.data(), query.docs.first.id);

      // Check if chat already exists
      final chatQuery = await FirebaseFirestore.instance.collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();
          
      String? existingChatId;
      for (var doc in chatQuery.docs) {
        List<dynamic> parts = doc.data()['participants'];
        if (parts.contains(otherUser.uid)) {
          existingChatId = doc.id;
          break;
        }
      }

      if (existingChatId != null) {
        if (mounted) {
          final doc = await FirebaseFirestore.instance.collection('chats').doc(existingChatId).get();
          final chat = ChatModel.fromMap(doc.data()!, doc.id);
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chat, otherUserId: otherUser.uid)));
        }
      } else {
        // Create new pending chat request
        final newChatId = const Uuid().v4();
        final newChat = ChatModel(
          chatId: newChatId,
          participants: [currentUser.uid, otherUser.uid],
          messages: [],
          status: 'pending',
          initiatorUid: currentUser.uid,
        );
        await FirebaseFirestore.instance.collection('chats').doc(newChatId).set(newChat.toMap());

        // Notify the other user
        await FirebaseFirestore.instance.collection('notifications').doc().set({
          'id': const Uuid().v4(),
          'targetUid': otherUser.uid,
          'senderUid': currentUser.uid,
          'chatId': newChatId,
          'title': 'New Chat Request',
          'body': '${currentUser.name} wants to chat with you',
          'type': 'chat_request',
          'isRead': false,
          'timestamp': Timestamp.now(),
        });

        if (mounted) {
          _usernameCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat request sent to ${otherUser.name}!')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showNewChatSheet(UserModel currentUser) {
    showModalBottomSheet(
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
              const Row(
                children: [
                   Icon(Icons.message_rounded, color: AppTheme.primaryGreen),
                   SizedBox(width: 8),
                   Text("New Direct Message", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter username to start chat...",
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _startNewChat(currentUser);
                  },
                  child: const Text("Start Chat", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteChat(String chatId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Chat"),
        content: const Text("Are you sure you want to delete this chat permanently?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat deleted')));
    }
  }

  Future<void> _acceptChat(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({'status': 'accepted'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat request accepted!')));
  }

  Future<void> _declineChat(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat request declined.')));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: currentUserAsync.when(
        data: (currentUser) {
          if (currentUser == null) return const Center(child: Text("Not logged in"));
          
          return CustomScrollView(
            slivers: [
              // ── Modern Header ────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: const Color(0xFF2E7D52),
                title: const Text('Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 70),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: "Search conversations...",
                                hintStyle: const TextStyle(color: Colors.white60),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.15),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                    onPressed: () => _showNewChatSheet(currentUser),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // ── Chat List ───────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats')
                    .where('participants', arrayContains: currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text("No messages yet. Start a conversation!")),
                    );
                  }

                  final chats = snapshot.data!.docs
                      .map((d) => ChatModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                      .toList();
                  
                  // Local sorting
                  chats.sort((a, b) {
                    if (a.messages.isEmpty) return 1;
                    if (b.messages.isEmpty) return -1;
                    return b.messages.last.timestamp.compareTo(a.messages.last.timestamp);
                  });

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final chat = chats[index];
                          final otherParticipants = chat.participants.where((id) => id != currentUser.uid).toList();
                          if (otherParticipants.isEmpty) return const SizedBox.shrink();
                          final otherUserId = otherParticipants.first;

                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
                              final otherUser = UserModel.fromMap(userSnap.data!.data() as Map<String, dynamic>, otherUserId);
                              
                              if (_searchQuery.isNotEmpty && !otherUser.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                                return const SizedBox.shrink();
                              }

                              return _buildChatTile(context, chat, otherUser, currentUser)
                                  .animate().fade(duration: 300.ms).slideY(begin: 0.1);
                            },
                          );
                        },
                        childCount: chats.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, s) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatModel chat, UserModel otherUser, UserModel currentUser) {
    final isPending = chat.status == 'pending';
    final isRequester = chat.initiatorUid == currentUser.uid;
    final lastMsgText = chat.messages.isNotEmpty 
        ? chat.messages.last.text 
        : isPending ? (isRequester ? 'Waiting for acceptance...' : 'Sent you a chat request') : 'Tap to chat';
    
    final hasUnread = chat.messages.isNotEmpty && chat.messages.last.senderId != currentUser.uid;

    if (isPending && !isRequester) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: ListTile(
          onLongPress: () => _deleteChat(chat.chatId),
          leading: _avatarWithGradient(otherUser.profileImageUrl, isOnline: otherUser.isOnline),
          title: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Wants to connect with you', style: TextStyle(color: Colors.orange, fontSize: 13)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28), onPressed: () => _acceptChat(chat.chatId)),
              IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 28), onPressed: () => _declineChat(chat.chatId)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: isPending && isRequester ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chat, otherUserId: otherUser.uid))),
        onLongPress: () => _deleteChat(chat.chatId),
        leading: _avatarWithGradient(otherUser.profileImageUrl, isOnline: otherUser.isOnline),
        title: Row(
          children: [
            Expanded(child: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (chat.messages.isNotEmpty)
              Text(
                timeago.format(chat.messages.last.timestamp, locale: 'en_short'),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMsgText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isPending ? Colors.grey : (hasUnread ? AppTheme.textMain : AppTheme.textSecondary),
                  fontWeight: hasUnread && !isPending ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (hasUnread && !isPending)
               Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)),
            if (isPending && isRequester)
               const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 14),
            if (chat.feedIdRequested != null && !chat.completed)
               const Icon(Icons.fastfood_rounded, color: Colors.amber, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _avatarWithGradient(String url, {bool isOnline = false}) {
    return CustomAvatar(
      imageUrl: url,
      radius: 24,
      placeholderIcon: Icons.person_rounded,
      isOnline: isOnline,
    );
  }
}
