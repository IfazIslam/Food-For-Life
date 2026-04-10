import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String gender;
  final String username;
  final String bio;
  final String addressState;
  final int impactPoints;
  final String profileImageUrl;
  final bool isOnline;
  final Timestamp? lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.gender,
    required this.username,
    required this.bio,
    required this.addressState,
    this.impactPoints = 0,
    this.profileImageUrl = '',
    this.isOnline = false,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'gender': gender,
      'username': username,
      'bio': bio,
      'addressState': addressState,
      'impactPoints': impactPoints,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'] ?? '',
      username: map['username'] ?? '',
      bio: map['bio'] ?? '',
      addressState: map['addressState'] ?? '',
      impactPoints: map['impactPoints']?.toInt() ?? 0,
      profileImageUrl: map['profileImageUrl'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] as Timestamp?,
    );
  }
}
