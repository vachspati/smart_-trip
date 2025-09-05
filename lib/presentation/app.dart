import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/home_page.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Trip Planner',
      theme: buildTheme(),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
