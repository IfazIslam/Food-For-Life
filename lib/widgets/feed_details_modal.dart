import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/feed_model.dart';
import '../theme/app_theme.dart';
import 'custom_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedDetailsModal extends StatelessWidget {
  final FeedModel feed;
  final String currentUid;
  final Function(FeedModel) onRequest;

  const FeedDetailsModal({
    super.key, 
    required this.feed,
    required this.currentUid,
    required this.onRequest,
  });

  static void show(BuildContext context, FeedModel feed, String currentUid, Function(FeedModel) onRequest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedDetailsModal(
        feed: feed,
        currentUid: currentUid,
        onRequest: onRequest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiryTime = feed.postedAt.add(Duration(hours: feed.timeDurationHours));
    final durationLeft = expiryTime.difference(DateTime.now());
    final isExpired = durationLeft.isNegative;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Image Header
              Stack(
                children: [
                  CustomNetworkImage(
                    imageUrl: feed.imageUrl,
                    height: 300,
                    width: double.infinity,
                    borderRadius: 0,
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        feed.tag,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Time Left
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            feed.foodName,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.red.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: isExpired ? Colors.red : AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isExpired ? "Expired" : "${durationLeft.inHours}h ${durationLeft.inMinutes.remainder(60)}m",
                                style: TextStyle(
                                  color: isExpired ? Colors.red : AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      "Posted ${timeago.format(feed.postedAt)}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feed.description,
                      style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
                    ),

                    const SizedBox(height: 32),
                    // Donor Card
                    const Text(
                      "Donated By",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.washedOutGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          CustomAvatar(imageUrl: feed.donorProfileImage, radius: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feed.donorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text(
                                  "Community Donor",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (feed.donorUid != currentUid && !isExpired) {
                            onRequest(feed);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (feed.donorUid == currentUid || isExpired) ? Colors.grey : AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          feed.donorUid == currentUid 
                              ? "Got it!" 
                              : (isExpired ? "Post Expired" : "Request Food"), 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
