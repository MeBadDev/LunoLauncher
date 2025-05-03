import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../models/app_model.dart';
import '../models/widget_model.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_provider.dart';
import 'draggable_widget.dart';

// Grid utility class for consistent grid calculations across the app
class GridCalculator {
  // Number of columns and rows to display on screen
  static const int columns = 4;
  static const int rows = 6;

  // Padding at screen edges
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 16.0;

  // Calculate grid cell width based on available screen width
  static double getCellWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate the original cell width
    final originalWidth = (screenWidth - (horizontalPadding * 2)) / columns;
    // Return one less than the original width (x-1)
    return originalWidth - 11;
  }

  // Calculate grid cell height based on available screen height
  static double getCellHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Reserve some space for status bar and potential UI elements at bottom
    final usableHeight = screenHeight - (verticalPadding * 2);
    return usableHeight / rows;
  }

  // Calculate grid position based on screen coordinates
  static Offset getGridPosition(BuildContext context, Offset rawPosition) {
    final cellWidth = getCellWidth(context);
    final cellHeight = getCellHeight(context);

    final gridX =
        ((rawPosition.dx - horizontalPadding) / cellWidth).round() * cellWidth +
        horizontalPadding;
    final gridY =
        ((rawPosition.dy - verticalPadding) / cellHeight).round() * cellHeight +
        verticalPadding;

    return Offset(gridX, gridY);
  }

  // Check if a position is within valid grid bounds
  static bool isValidGridPosition(BuildContext context, Offset position) {
    final size = MediaQuery.of(context).size;
    return position.dx >= horizontalPadding &&
        position.dx <= size.width - horizontalPadding &&
        position.dy >= verticalPadding &&
        position.dy <= size.height - verticalPadding;
  }
}

class CustomHomeView extends StatefulWidget {
  const CustomHomeView({super.key});

  @override
  State<CustomHomeView> createState() => _CustomHomeViewState();
}

class _CustomHomeViewState extends State<CustomHomeView> {
  List<DraggableAppIcon> draggableIcons = [];
  List<DraggableWidget> draggableWidgets = [];

  @override
  void initState() {
    super.initState();
    _loadIconPositions();
    _loadWidgets();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final widgetProvider = Provider.of<WidgetProvider>(context);

    // Update draggable icons when apps change
    _updateDraggableIcons(
      appProvider.apps.where((app) => app.isFavorite).toList(),
    );

    // Update widgets when they change
    _updateDraggableWidgets(widgetProvider.widgets);

    return GestureDetector(
      // Add long press on the background to show the widget menu
      onLongPress: () => _showAddWidgetDialog(context),
      child: Container(
        decoration: const BoxDecoration(
          // The container will be transparent to show the wallpaper behind
          color: Colors.transparent,
        ),
        child: Stack(
          children: [
            // Add all draggable widgets
            ...draggableWidgets,

            // Add all draggable app icons
            ...draggableIcons,
          ],
        ),
      ),
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

  void _updateDraggableWidgets(List<WidgetModel> widgets) {
    // Rebuild whenever the widget list changes
    if (draggableWidgets.length != widgets.length) {
      setState(() {
        draggableWidgets =
            widgets.map((widget) {
              // Get the widget's position from the widget provider
              final widgetProvider = Provider.of<WidgetProvider>(
                context,
                listen: false,
              );
              final position = widgetProvider.getWidgetPosition(widget.id);

              return DraggableWidget(
                widget: widget,
                initialPosition: position,
                onPositionChanged:
                    (newPosition) => widgetProvider.saveWidgetPosition(
                      widget.id,
                      newPosition,
                    ),
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

  Future<void> _loadWidgets() async {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    await widgetProvider.loadWidgets();
  }

  Offset _getSavedPosition(String packageName) {
    final savedX = _getIconPositionFromPrefs('${packageName}_x');
    final savedY = _getIconPositionFromPrefs('${packageName}_y');

    if (savedX != null && savedY != null) {
      // Use the dynamic grid system to snap saved positions
      final rawPos = Offset(savedX, savedY);
      return GridCalculator.getGridPosition(context, rawPos);
    }

    // Default positions arranged in a grid
    final index = draggableIcons.length;
    final cellWidth = GridCalculator.getCellWidth(context);
    final cellHeight = GridCalculator.getCellHeight(context);

    final iconsPerRow = GridCalculator.columns;
    final row = index ~/ iconsPerRow;
    final col = index % iconsPerRow;

    // Calculate position based on grid cell
    final x = col * cellWidth + GridCalculator.horizontalPadding;
    final y = row * cellHeight + GridCalculator.verticalPadding;

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

  void _showAddWidgetDialog(BuildContext context) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    Vibration.vibrate(duration: 50);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Add Widget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildWidgetOption(
                      context,
                      Icons.access_time,
                      'Clock',
                      WidgetType.clock,
                      widgetProvider,
                    ),
                    _buildWidgetOption(
                      context,
                      Icons.cloud,
                      'Weather',
                      WidgetType.weather,
                      widgetProvider,
                    ),
                    _buildWidgetOption(
                      context,
                      Icons.calendar_today,
                      'Calendar',
                      WidgetType.calendar,
                      widgetProvider,
                    ),
                    _buildWidgetOption(
                      context,
                      Icons.note,
                      'Notes',
                      WidgetType.notes,
                      widgetProvider,
                    ),
                    _buildWidgetOption(
                      context,
                      Icons.photo,
                      'Photo',
                      WidgetType.photo,
                      widgetProvider,
                    ),
                    _buildWidgetOption(
                      context,
                      Icons.battery_charging_full,
                      'Battery',
                      WidgetType.battery,
                      widgetProvider,
                    ),
                    _buildWidgetOption(
                      context,
                      Icons.widgets,
                      'Custom',
                      WidgetType.custom,
                      widgetProvider,
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildWidgetOption(
    BuildContext context,
    IconData icon,
    String name,
    WidgetType type,
    WidgetProvider widgetProvider,
  ) {
    return InkWell(
      onTap: () {
        widgetProvider.addWidget(type);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
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

class _DraggableAppIconState extends State<DraggableAppIcon>
    with SingleTickerProviderStateMixin {
  late Offset position;
  // Sizes for alignment calculation
  final double iconContainerSize = 60.0;
  final double iconSize = 40.0;
  final double labelHeight = 20.0;
  final double iconPadding = 8.0;
  final double spacingHeight = 4.0;

  // Used to track if we're currently dragging
  bool isDragging = false;
  // Store overlay entry reference when dragging
  OverlayEntry? _overlayEntry;
  // Track drag position
  Offset _dragPosition = Offset.zero;
  // Last snap position for smooth animation
  Offset _lastSnapPosition = Offset.zero;

  // Animation related variables for drag animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.addListener(() {
      setState(() {
        if (_lastSnapPosition != null && _dragPosition != null) {
          position =
              Offset.lerp(_lastSnapPosition, _dragPosition, _animation.value)!;
        }
      });
    });
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lastSnapPosition = _dragPosition;
      }
    });
  }

  @override
  void dispose() {
    // Ensure we remove any overlay entries when widget is disposed
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: widget.app.launchFunction,
        onLongPress: () => _showAppOptions(context),
        onPanStart: (details) {
          setState(() {
            isDragging = true;
            _dragPosition = details.globalPosition;
          });
          _createDragOverlay(themeProvider);
        },
        onPanUpdate: (details) {
          if (isDragging) {
            setState(() {
              _dragPosition = details.globalPosition;
            });
            // Update the overlay position when drag updates
            _updateOverlayPosition();
            // Start the animation from the beginning
            _animationController.reset();
            _animationController.forward();
          }
        },
        onPanEnd: (details) {
          // Apply final position when drag ends
          if (isDragging) {
            final statusBarHeight = MediaQuery.of(context).padding.top;

            // Calculate final position with snapping using our grid calculator
            final snappedPosition = _getSnappedPosition(
              _dragPosition,
              statusBarHeight,
            );

            // Store the current position as start and target as the snapped position
            _lastSnapPosition = position;
            _dragPosition = snappedPosition;

            // Start the animation from the beginning
            _animationController.reset();
            _animationController.forward();

            setState(() {
              isDragging = false;
            });

            // Remove the overlay immediately
            _removeOverlay();

            // Add a one-time listener to save position after animation completes
            _animationController.addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                widget.onPositionChanged(_dragPosition);
                // Remove this listener to avoid memory leaks
                _animationController.removeStatusListener((s) {});
              }
            });
          }
        },
        child: Opacity(
          opacity: isDragging ? 0.5 : 1.0,
          child: _buildAppIcon(themeProvider, false),
        ),
      ),
    );
  }

  // Calculate a grid-snapped position from a given raw position
  Offset _getSnappedPosition(Offset rawOffset, double statusBarHeight) {
    // Calculate the total widget size (icon + label)
    final totalWidgetSize = Size(
      80.0, // The width of our widget (from container width)
      iconContainerSize +
          spacingHeight +
          labelHeight, // Total height of the widget
    );

    // Calculate position adjusting for widget center and status bar
    final adjustedOffset = Offset(
      rawOffset.dx - (totalWidgetSize.width / 2),
      rawOffset.dy - (totalWidgetSize.height / 2) - statusBarHeight,
    );

    // Use the grid calculator to snap to grid
    final snappedPosition = GridCalculator.getGridPosition(
      context,
      adjustedOffset,
    );

    // Get screen size to apply boundaries
    final screenSize = MediaQuery.of(context).size;

    // Calculate minimum and maximum allowed positions
    final minX = GridCalculator.horizontalPadding;
    final minY = GridCalculator.verticalPadding;
    final maxX =
        screenSize.width -
        GridCalculator.horizontalPadding -
        totalWidgetSize.width;
    final maxY =
        screenSize.height -
        GridCalculator.verticalPadding -
        totalWidgetSize.height;

    // Apply boundaries to ensure the icon stays within screen bounds
    final boundedX = snappedPosition.dx.clamp(minX, maxX);
    final boundedY = snappedPosition.dy.clamp(minY, maxY);

    return Offset(boundedX, boundedY);
  }

  // Create overlay for drag preview with snapping
  void _createDragOverlay(ThemeProvider themeProvider) {
    final overlay = Overlay.of(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Set initial position as the last snap position
    _lastSnapPosition = position;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        // Get current animated position
        final statusBarHeight = MediaQuery.of(context).padding.top;

        // Calculate snapped position
        final snappedPosition = _getSnappedPosition(
          _dragPosition,
          statusBarHeight,
        );

        // Interpolate between positions using cubic animation
        final currentAnimatedPosition =
            _animation.value < 1.0
                ? Offset.lerp(
                  _lastSnapPosition,
                  snappedPosition,
                  _animation.value,
                )!
                : snappedPosition;

        return Positioned(
          left: currentAnimatedPosition.dx,
          top: currentAnimatedPosition.dy,
          child: Material(
            color: Colors.transparent,
            elevation: 4.0,
            child: _buildAppIcon(themeProvider, true),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  // Update overlay position during drag with animation
  void _updateOverlayPosition() {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Calculate the new snapped position
    final newSnappedPosition = _getSnappedPosition(
      _dragPosition,
      statusBarHeight,
    );

    // If position changed significantly, animate to new position
    if ((newSnappedPosition - _lastSnapPosition).distance > 10) {
      // Start smooth animation to new position
      _animationController.reset();
      _animationController.forward();

      // Mark overlay for rebuild
      _overlayEntry?.markNeedsBuild();

      // Update the last snap position after animation completes
      if (_animation.value >= 0.9) {
        _lastSnapPosition = newSnappedPosition;
      }
    } else {
      // Just rebuild overlay without animation for small movements
      _overlayEntry?.markNeedsBuild();
    }
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
