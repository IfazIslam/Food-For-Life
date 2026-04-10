import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/feed_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/imgbb_service.dart';

class UploadFeedScreen extends ConsumerStatefulWidget {
  const UploadFeedScreen({super.key});

  @override
  ConsumerState<UploadFeedScreen> createState() => _UploadFeedScreenState();
}

class _UploadFeedScreenState extends ConsumerState<UploadFeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  double _timeDuration = 24.0;
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _uploadPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    setState(() => _isUploading = true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      final imageUrl = await ImgBBService.uploadImage(_imageFile!);
      if (imageUrl == null) throw Exception("Image upload failed");

      final feedId = const Uuid().v4();
      final tag = _tagCtrl.text.trim();
      
      final newFeed = FeedModel(
        feedId: feedId,
        donorUid: user.uid,
        donorUsername: user.username,
        donorName: user.name,
        donorProfileImage: user.profileImageUrl,
        donorState: user.addressState,
        foodName: _foodNameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        timeDurationHours: _timeDuration.toInt(),
        tag: tag.startsWith('#') ? tag.toLowerCase() : '#${tag.toLowerCase()}',
        postedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('feeds').doc(feedId).set(newFeed.toMap());
      
      await FirebaseFirestore.instance.collection('notifications').doc().set({
        'id': feedId,
        'targetUid': user.uid,
        'senderUid': user.uid, // Self-notification
        'chatId': null,
        'title': 'Feed Posted',
        'body': 'You successfully posted ${newFeed.foodName}',
        'type': 'system',
        'isRead': false,
        'timestamp': Timestamp.now(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post created successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    
    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: CustomScrollView(
        slivers: [
          // ── Modern Header ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D52),
            title: const Text('Share Food', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    child: Icon(Icons.volunteer_activism_rounded, color: Colors.white24, size: 50),
                  ),
                ),
              ),
            ),
          ),

          // ── Form Content ────────────────────────────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker Card
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: AppTheme.washedOutGreen.withOpacity(0.3), shape: BoxShape.circle),
                                    child: const Icon(Icons.add_a_photo_rounded, size: 40, color: AppTheme.primaryGreen),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text("Tap to select food image", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                  const Text("Show them what you're sharing!", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              ),
                      ),
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // Inputs Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            controller: _foodNameCtrl,
                            hint: 'What food are you sharing?',
                            label: 'Food Name',
                            icon: Icons.fastfood_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _descCtrl,
                            hint: 'Describe quantity, condition, etc.',
                            label: 'Description',
                            icon: Icons.description_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _tagCtrl,
                            hint: 'e.g. #meal #burger #rice',
                            label: 'Tag',
                            icon: Icons.tag_rounded,
                          ),
                        ],
                      ),
                    ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // Duration Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Edible Duration", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain)
                          ),
                          const Text("How long will this food stay fresh?", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.timer_rounded, color: AppTheme.primaryGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "${_timeDuration.toInt()} Hours", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen)
                              ),
                            ],
                          ),
                          Slider(
                            value: _timeDuration,
                            min: 1,
                            max: 72,
                            activeColor: AppTheme.primaryGreen,
                            inactiveColor: AppTheme.washedOutGreen,
                            onChanged: (v) => setState(() => _timeDuration = v),
                          ),
                        ],
                      ),
                    ).animate(delay: 200.ms).fade(duration: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 32),

                    // Submit Button
                    _isUploading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                              ),
                              onPressed: _uploadPost,
                              child: const Text('Share Donation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ).animate(delay: 300.ms).fade(duration: 400.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            filled: true,
            fillColor: const Color(0xFFF5F7F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (v) => v!.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }
}
