import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'user_details_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../widgets/custom_image.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatModel chat;
  final String otherUserId;

  const ChatDetailScreen({super.key, required this.chat, required this.otherUserId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  Future<void> _sendMessage(String senderId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    final newMsg = ChatMessage(senderId: senderId, text: text, timestamp: DateTime.now());
    
    await FirebaseFirestore.instance.collection('chats').doc(widget.chat.chatId).update({
      'messages': FieldValue.arrayUnion([newMsg.toMap()])
    });

    await FirebaseFirestore.instance.collection('notifications').doc().set({
      'id': const Uuid().v4(),
      'targetUid': widget.otherUserId,
      'title': 'New Message',
      'body': 'You have a new message regarding a donation.',
      'type': 'chat',
      'isRead': false,
      'timestamp': Timestamp.now(),
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _grantFood(UserModel donor, ChatModel currentChat) async {
    final feedDoc = await FirebaseFirestore.instance.collection('feeds').doc(currentChat.feedIdRequested).get();
    if (!feedDoc.exists) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feed no longer exists.")));
      return;
    }
    
    final feedOwnerId = feedDoc.data()!['donorUid'];
    if (feedOwnerId != donor.uid) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only the post owner can grant food.")));
      return;
    }

    await FirebaseFirestore.instance.collection('chats').doc(currentChat.chatId).update({'accepted': true});
    
    final systemMsg = ChatMessage(senderId: "SYSTEM", text: "🎁 Food Granted! Do you accept?", timestamp: DateTime.now());
    await FirebaseFirestore.instance.collection('chats').doc(currentChat.chatId).update({
      'messages': FieldValue.arrayUnion([systemMsg.toMap()])
    });

    await FirebaseFirestore.instance.collection('notifications').doc().set({
      'id': const Uuid().v4(),
      'targetUid': widget.otherUserId,
      'title': 'Food Granted!',
      'body': '${donor.name} has granted you the food. Please accept it in the chat.',
      'type': 'system',
      'isRead': false,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _acceptFood(UserModel receiver, ChatModel currentChat) async {
    final feedDoc = await FirebaseFirestore.instance.collection('feeds').doc(currentChat.feedIdRequested).get();
    if (!feedDoc.exists) return;
    
    final feedOwnerId = feedDoc.data()!['donorUid'];
    if (feedOwnerId == receiver.uid) return;

    await FirebaseFirestore.instance.collection('users').doc(feedOwnerId).update({'impactPoints': FieldValue.increment(10)});
    await FirebaseFirestore.instance.collection('feeds').doc(currentChat.feedIdRequested).delete();
    await FirebaseFirestore.instance.collection('chats').doc(currentChat.chatId).update({'completed': true});

    final systemMsg = ChatMessage(senderId: "SYSTEM", text: "✅ Food Transfer Completed! +10 Impact Points to Donor.", timestamp: DateTime.now());
    await FirebaseFirestore.instance.collection('chats').doc(currentChat.chatId).update({
      'messages': FieldValue.arrayUnion([systemMsg.toMap()])
    });
  }
  
  Future<void> _acceptChat() async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.chat.chatId).update({'status': 'accepted'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat request accepted!')));
  }

  Future<void> _declineChat() async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.chat.chatId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat request declined.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: currentUser == null 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)) 
          : Column(
              children: [
                // ── Modern AppBar with Recipient Info ───────────────────
                _buildHeader(context),

                // ── Chat Area ──────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('chats').doc(widget.chat.chatId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final chatData = ChatModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
                      final messages = chatData.messages.reversed.toList();

                      return Column(
                        children: [
                          _buildStatusBanner(chatData, currentUser),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              reverse: true,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isMe = msg.senderId == currentUser.uid;
                                final isSystem = msg.senderId == "SYSTEM";

                                if (isSystem) return _buildSystemMessage(msg.text);

                                return _buildMessageBubble(msg, isMe)
                                    .animate().fade(duration: 200.ms).slideY(begin: 0.05);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ── Input Field ────────────────────────────────────────
                _buildInputArea(currentUser),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E3B), Color(0xFF57AB74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).snapshots(),
        builder: (context, snapshot) {
          final u = snapshot.hasData && snapshot.data!.exists
              ? UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id)
              : null;

          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              if (u != null) ...[
                Expanded(
                  child: Row(
                    children: [
                      CustomAvatar(
                        imageUrl: u.profileImageUrl, 
                        radius: 18, 
                        placeholderIcon: Icons.person_rounded,
                        isOnline: u.isOnline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                            Text(
                              u.isOnline 
                                  ? 'Online' 
                                  : (u.lastSeen != null ? 'Last seen \${timeago.format(u.lastSeen!.toDate())}' : 'Offline'), 
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsScreen(user: u))),
                ),
              ] else ...[
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(ChatModel chatData, UserModel currentUser) {
    if (chatData.status == 'pending') {
      final isInitiator = chatData.initiatorUid == currentUser.uid;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isInitiator ? Colors.orange.shade50 : Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isInitiator ? Colors.orange.shade200 : Colors.amber.shade200)),
        child: Column(
          children: [
            Row(
              children: [
                Icon(isInitiator ? Icons.hourglass_empty_rounded : Icons.person_add_rounded, color: isInitiator ? Colors.orange : Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isInitiator ? 'Waiting for response...' : 'Sent you a chat request',
                    style: TextStyle(color: isInitiator ? Colors.orange : Colors.amber.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (!isInitiator) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, elevation: 0),
                      onPressed: _acceptChat,
                      child: const Text("Accept", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), elevation: 0),
                      onPressed: _declineChat,
                      child: const Text("Decline", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    if (chatData.feedIdRequested != null && !chatData.completed) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
        child: Row(
          children: [
            const Icon(Icons.fastfood_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text("Food Request Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            if (!chatData.accepted)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0),
                onPressed: () => _grantFood(currentUser, chatData),
                child: const Text("Grant", style: TextStyle(fontSize: 12)),
              ),
            if (chatData.accepted)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, elevation: 0),
                onPressed: () => _acceptFood(currentUser, chatData),
                child: const Text("Accept", style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSystemMessage(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : AppTheme.textMain, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              timeago.format(msg.timestamp, locale: 'en_short'),
              style: const TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(UserModel currentUser) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(widget.chat.chatId).snapshots(),
      builder: (context, snap) {
        final isPending = snap.hasData 
            ? (ChatModel.fromMap(snap.data!.data() as Map<String, dynamic>, snap.data!.id).status == 'pending') 
            : false;
            
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF5F7F5), borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    controller: _msgCtrl,
                    enabled: !isPending,
                    decoration: InputDecoration(
                      hintText: isPending ? 'Waiting for approval...' : 'Type a message...',
                      hintStyle: const TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: isPending ? Colors.grey.shade300 : AppTheme.primaryGreen,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: isPending ? null : () => _sendMessage(currentUser.uid),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
