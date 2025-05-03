import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: appProvider.categories.length,
        itemBuilder: (context, index) {
          final category = appProvider.categories[index];
          final isSelected = category == appProvider.currentCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  appProvider.setCurrentCategory(category);
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              avatar: _getCategoryIcon(category, isSelected, context),
            ),
          );
        },
      ),
    );
  }

  Widget? _getCategoryIcon(
    String category,
    bool isSelected,
    BuildContext context,
  ) {
    Color iconColor =
        isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary;

    IconData iconData;

    switch (category) {
      case 'Favorites':
        iconData = Icons.star;
        break;
      case 'Social':
        iconData = Icons.people;
        break;
      case 'Productivity':
        iconData = Icons.work;
        break;
      case 'Entertainment':
        iconData = Icons.movie;
        break;
      case 'Games':
        iconData = Icons.sports_esports;
        break;
      default:
        iconData = Icons.apps;
        break;
    }

    return Icon(iconData, size: 16, color: iconColor);
  }
}
