import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const FoodForLifeApp());
}

class FoodForLifeApp extends StatelessWidget {
  const FoodForLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food For Life',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const LoginPage(),
    );
  }
}
