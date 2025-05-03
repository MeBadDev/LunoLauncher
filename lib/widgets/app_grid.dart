import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_model.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';

class AppGrid extends StatelessWidget {
  const AppGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    if (appProvider.filteredApps.isEmpty) {
      return Center(
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
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio:
            0.8, // Adjusted from 1.0 to 0.8 to provide more vertical space
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: appProvider.filteredApps.length,
      itemBuilder: (context, index) {
        final app = appProvider.filteredApps[index];
        return AppIconWidget(app: app);
      },
    );
  }
}

class AppIconWidget extends StatelessWidget {
  final AppModel app;

  const AppIconWidget({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return InkWell(
      onTap: app.launchFunction,
      onLongPress: () => _showAppOptions(context),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  themeProvider.useBlur
                      ? [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            // Ensure the icon has a fixed size
            height: 48,
            width: 48,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                // Center the icon and ensure it fits within the container
                Center(child: SizedBox(height: 40, width: 40, child: app.icon)),
                if (app.isFavorite)
                  Icon(
                    Icons.star,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppOptions(BuildContext context) {
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
                  app.isFavorite ? 'Remove from favorites' : 'Add to favorites',
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
                  _showCategorySelector(context);
                },
              ),
            ],
          ),
    );
  }

  void _showCategorySelector(BuildContext context) {
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
