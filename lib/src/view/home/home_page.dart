import 'package:flutter/material.dart';
import 'package:realm_gony3t/realm_gony3T.dart';
import 'package:realm_gony3t/src/utils/utils.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String routeName = '$initRoute/home-page';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, SettingPage.routeName);
          },
          child: const Text('Go to Settings'),
        ),
      ),
    );
  }
}
