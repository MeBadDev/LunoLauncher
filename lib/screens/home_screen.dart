import 'package:flutter/material.dart';
import '../widgets/app_grid.dart';
import '../widgets/category_selector.dart';
import '../widgets/settings_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button from closing the launcher
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Removed clock widget section

              // Category selector
              const CategorySelector(),

              // App grid
              const Expanded(child: AppGrid()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          child: const Icon(Icons.settings),
        ),
      ),
    );
  }
}
