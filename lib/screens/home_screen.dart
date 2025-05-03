import 'package:flutter/material.dart';
import '../widgets/app_grid.dart';
import '../widgets/category_selector.dart';
import '../widgets/clock_widget.dart';
import '../widgets/settings_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section with clock and date
            Container(
              height: 180,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              child: const ClockWidget(),
            ),

            // Removed search bar

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
    );
  }
}
