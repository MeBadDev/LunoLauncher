import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';

class CustomHomeView extends StatefulWidget {
  const CustomHomeView({super.key});

  @override
  State<CustomHomeView> createState() => _CustomHomeViewState();
}

class _CustomHomeViewState extends State<CustomHomeView> {
  List<DraggableAppIcon> draggableIcons = [];

  @override
  void initState() {
    super.initState();
    _loadIconPositions();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    // Update draggable icons when apps change
    _updateDraggableIcons(
      appProvider.apps.where((app) => app.isFavorite).toList(),
    );

    return Container(
      decoration: const BoxDecoration(
        // The container will be transparent to show the wallpaper behind
        color: Colors.transparent,
      ),
      child: Stack(children: draggableIcons),
    );
  }

  void _updateDraggableIcons(List<AppModel> favoriteApps) {
    // Only rebuild if the number of icons has changed
    if (draggableIcons.length != favoriteApps.length) {
      // Create draggable icons for each favorite app
      setState(() {
        draggableIcons =
            favoriteApps.map((app) {
              // Get saved position or use default
              final position = _getSavedPosition(app.packageName);

              return DraggableAppIcon(
                app: app,
                initialPosition: position,
                onPositionChanged:
                    (newPosition) =>
                        _saveIconPosition(app.packageName, newPosition),
              );
            }).toList();
      });
    }
  }

  Future<void> _loadIconPositions() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Rebuild icons with saved positions
    setState(() {
      draggableIcons =
          appProvider.apps.where((app) => app.isFavorite).map((app) {
            final position = _getSavedPosition(app.packageName);

            return DraggableAppIcon(
              app: app,
              initialPosition: position,
              onPositionChanged:
                  (newPosition) =>
                      _saveIconPosition(app.packageName, newPosition),
            );
          }).toList();
    });
  }

  Offset _getSavedPosition(String packageName) {
    final screenSize = MediaQuery.of(context).size;
    final savedX = _getIconPositionFromPrefs('${packageName}_x');
    final savedY = _getIconPositionFromPrefs('${packageName}_y');

    if (savedX != null && savedY != null) {
      return Offset(savedX, savedY);
    }

    // Default positions arranged in a grid
    final index = draggableIcons.length;
    final iconsPerRow = 4;
    final row = index ~/ iconsPerRow;
    final col = index % iconsPerRow;

    final x = col * (screenSize.width / iconsPerRow) + 40.0;
    final y = row * 120.0 + 100.0;

    return Offset(x, y);
  }

  double? _getIconPositionFromPrefs(String key) {
    // This would be implemented to load from SharedPreferences
    // For now, return null to use default positions
    return null;
  }

  Future<void> _saveIconPosition(String packageName, Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${packageName}_x', position.dx);
    await prefs.setDouble('${packageName}_y', position.dy);
  }
}

class DraggableAppIcon extends StatefulWidget {
  final AppModel app;
  final Offset initialPosition;
  final Function(Offset) onPositionChanged;

  const DraggableAppIcon({
    super.key,
    required this.app,
    required this.initialPosition,
    required this.onPositionChanged,
  });

  @override
  State<DraggableAppIcon> createState() => _DraggableAppIconState();
}

class _DraggableAppIconState extends State<DraggableAppIcon> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable<AppModel>(
        data: widget.app,
        feedback: Material(
          color: Colors.transparent,
          child: _buildAppIcon(themeProvider, true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildAppIcon(themeProvider, false),
        ),
        onDragEnd: (details) {
          setState(() {
            position = details.offset;
            // Account for the position offset within the widget
            position = Offset(
              position.dx - 24,
              position.dy - 24 - MediaQuery.of(context).padding.top,
            );
            widget.onPositionChanged(position);
          });
        },
        child: _buildAppIcon(themeProvider, false),
      ),
    );
  }

  Widget _buildAppIcon(ThemeProvider themeProvider, bool isDragging) {
    return GestureDetector(
      onTap: widget.app.launchFunction,
      onLongPress: () => _showAppOptions(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isDragging
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
                      : Theme.of(context).colorScheme.surface.withOpacity(0.6),
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
            height: 60,
            width: 60,
            child: Center(
              child: SizedBox(height: 40, width: 40, child: widget.app.icon),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.app.name,
              textAlign: TextAlign.center,
              maxLines: 1,
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
                title: Text(widget.app.name),
                subtitle: Text(widget.app.packageName),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove from home screen'),
                onTap: () {
                  if (widget.app.isFavorite) {
                    appProvider.toggleFavorite(widget.app);
                  }
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
                    selected: widget.app.category == category,
                    trailing:
                        widget.app.category == category
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () {
                      appProvider.setAppCategory(widget.app, category);
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
