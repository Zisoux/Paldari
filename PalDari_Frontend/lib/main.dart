import 'package:flutter/material.dart';
import 'screens/posts_screen.dart'; // 파일 경로가 lib/screens/posts_screen.dart 여야 함

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PalDari',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const PostsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
