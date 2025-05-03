import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/app_model.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_home_view.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/clock_widget.dart';
import '../widgets/settings_page.dart';

class CustomHomeScreen extends StatefulWidget {
  const CustomHomeScreen({super.key});

  @override
  State<CustomHomeScreen> createState() => _CustomHomeScreenState();
}

class _CustomHomeScreenState extends State<CustomHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      // Use transparent scaffold to allow wallpaper or gradient to show through
      backgroundColor: Colors.transparent,
      // Container with wallpaper or gradient background
      body: Container(
        decoration: _buildBackgroundDecoration(appProvider.wallpaperPath),
        child: SafeArea(
          child: Stack(
            children: [
              // Draggable icons area - covers the whole screen
              const Positioned.fill(child: CustomHomeView()),

              // Top section with clock
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Subtle gradient for better text visibility
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const ClockWidget(),
                ),
              ),

              // Search bar at the bottom
              const Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: SearchBarWidget(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'App Drawer',
        onPressed: () {
          // Navigate to app grid when tapped
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppDrawerScreen()),
          );
        },
        child: const Icon(Icons.apps),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(String? wallpaperPath) {
    // If we have a wallpaper image, use it
    if (wallpaperPath != null) {
      final file = File(wallpaperPath);
      if (file.existsSync()) {
        return BoxDecoration(
          image: DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha(
                51,
              ), // 0.2 opacity converted to alpha value
              BlendMode.darken,
            ),
          ),
        );
      }
    }

    // Otherwise fall back to a gradient
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue.shade800, Colors.purple.shade900],
      ),
    );
  }
}

class AppDrawerScreen extends StatelessWidget {
  const AppDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          const SearchBarWidget(),

          // Category selector
          _buildCategorySelector(context),

          // App grid
          _buildAppGrid(context),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: appProvider.categories.length,
        itemBuilder: (context, index) {
          final category = appProvider.categories[index];
          final isSelected = category == appProvider.currentCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  appProvider.setCurrentCategory(category);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppGrid(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    if (appProvider.filteredApps.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.app_shortcut, size: 48),
              const SizedBox(height: 16),
              Text(
                appProvider.searchQuery.isEmpty
                    ? 'No apps in this category'
                    : 'No matching apps found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: appProvider.filteredApps.length,
        itemBuilder: (context, index) {
          final app = appProvider.filteredApps[index];
          return _buildAppItem(context, app);
        },
      ),
    );
  }

  Widget _buildAppItem(BuildContext context, AppModel app) {
    return InkWell(
      onTap: app.launchFunction,
      onLongPress: () => _showAppOptions(context, app),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            height: 48,
            width: 48,
            child: Center(child: app.icon),
          ),
          const SizedBox(height: 8),
          Text(
            app.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showAppOptions(BuildContext context, AppModel app) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(app.name),
                subtitle: Text(app.packageName),
              ),
              ListTile(
                leading: Icon(app.isFavorite ? Icons.star : Icons.star_border),
                title: Text(
                  app.isFavorite
                      ? 'Remove from home screen'
                      : 'Add to home screen',
                ),
                onTap: () {
                  appProvider.toggleFavorite(app);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Set category'),
                onTap: () {
                  Navigator.pop(context);
                  _showCategorySelector(context, app);
                },
              ),
            ],
          ),
    );
  }

  void _showCategorySelector(BuildContext context, AppModel app) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Category'),
            content: SizedBox(
              width: double.minPositive,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: appProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = appProvider.categories[index];
                  if (category == 'Favorites') return const SizedBox.shrink();

                  return ListTile(
                    title: Text(category),
                    selected: app.category == category,
                    trailing:
                        app.category == category
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () {
                      appProvider.setAppCategory(app, category);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
    );
  }
}
