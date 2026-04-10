import 'package:cloud_firestore/cloud_firestore.dart';

class FeedModel {
  final String feedId;
  final String donorUid;
  final String donorUsername;
  final String donorName;
  final String donorState;
  final String donorProfileImage;
  final String foodName;
  final String description;
  final String imageUrl;
  final int timeDurationHours;
  final String tag;
  final DateTime postedAt;

  FeedModel({
    required this.feedId,
    required this.donorUid,
    required this.donorUsername,
    required this.donorName,
    required this.donorState,
    required this.donorProfileImage,
    required this.foodName,
    required this.description,
    required this.imageUrl,
    required this.timeDurationHours,
    required this.tag,
    required this.postedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'feedId': feedId,
      'donorUid': donorUid,
      'donorUsername': donorUsername,
      'donorName': donorName,
      'donorState': donorState,
      'donorProfileImage': donorProfileImage,
      'foodName': foodName,
      'description': description,
      'imageUrl': imageUrl,
      'timeDurationHours': timeDurationHours,
      'tag': tag,
      'postedAt': Timestamp.fromDate(postedAt),
    };
  }

  factory FeedModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedModel(
      feedId: id,
      donorUid: map['donorUid'] ?? '',
      donorUsername: map['donorUsername'] ?? '',
      donorName: map['donorName'] ?? '',
      donorState: map['donorState'] ?? '',
      donorProfileImage: map['donorProfileImage'] ?? '',
      foodName: map['foodName'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      timeDurationHours: map['timeDurationHours']?.toInt() ?? 0,
      tag: map['tag'] ?? '',
      postedAt: (map['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
