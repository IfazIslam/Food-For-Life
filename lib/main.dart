import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodforlife/utils/app_router.dart';
import 'package:foodforlife/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodforlife/providers/auth_provider.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  
  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(
    const ProviderScope(
      child: FoodForLifeApp(),
    ),
  );
}

class FoodForLifeApp extends ConsumerStatefulWidget {
  const FoodForLifeApp({super.key});

  @override
  ConsumerState<FoodForLifeApp> createState() => _FoodForLifeAppState();
}

class _FoodForLifeAppState extends ConsumerState<FoodForLifeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.inactive) {
      _updateStatus(true);
    } else {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint("Error updating status: $e"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Listen to auth changes to update status immediately on login/logout
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null) {
        // User logged in
        _updateStatus(true);
      }
    });

    return MaterialApp.router(
      title: 'Food for Life',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
