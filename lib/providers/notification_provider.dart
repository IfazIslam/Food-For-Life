import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
   final user = ref.watch(currentUserProvider).value;
   if (user == null) return Stream.value(0);

   return FirebaseFirestore.instance
       .collection('notifications')
       .where('targetUid', isEqualTo: user.uid)
       .where('isRead', isEqualTo: false)
       .snapshots()
       .map((snapshot) => snapshot.docs.length);
});
