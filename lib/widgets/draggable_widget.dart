import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/widget_model.dart';
import '../providers/widget_provider.dart';
import '../providers/theme_provider.dart';
import 'custom_home_view.dart';

class DraggableWidget extends StatefulWidget {
  final WidgetModel widget;
  final Offset initialPosition;
  final Function(Offset) onPositionChanged;

  const DraggableWidget({
    super.key,
    required this.widget,
    required this.initialPosition,
    required this.onPositionChanged,
  });

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget>
    with SingleTickerProviderStateMixin {
  late Offset position;
  bool isDragging = false;
  OverlayEntry? _overlayEntry;
  Offset _dragPosition = Offset.zero;
  Offset _lastSnapPosition = Offset.zero;

  // Animation related variables
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;

    // Initialize animation controller
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
        if (_lastSnapPosition != Offset.zero && _dragPosition != Offset.zero) {
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
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Get the size of the widget in pixels based on grid units
  Size _getWidgetSize(BuildContext context) {
    final cellWidth = GridCalculator.getCellWidth(context);
    final cellHeight = GridCalculator.getCellHeight(context);

    return Size(
      cellWidth * widget.widget.width,
      cellHeight * widget.widget.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final widgetSize = _getWidgetSize(context);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => _showWidgetOptions(context),
        onLongPress: () => _showWidgetOptions(context),
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
            _updateOverlayPosition();
            _animationController.reset();
            _animationController.forward();
          }
        },
        onPanEnd: (details) {
          if (isDragging) {
            final statusBarHeight = MediaQuery.of(context).padding.top;

            final snappedPosition = _getSnappedPosition(
              _dragPosition,
              statusBarHeight,
            );

            _lastSnapPosition = position;
            _dragPosition = snappedPosition;

            _animationController.reset();
            _animationController.forward();

            setState(() {
              isDragging = false;
            });

            _removeOverlay();

            _animationController.addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                widget.onPositionChanged(_dragPosition);
                _animationController.removeStatusListener((s) {});
              }
            });
          }
        },
        child: Opacity(
          opacity: isDragging ? 0.5 : 1.0,
          child: _buildWidget(themeProvider, widgetSize, false),
        ),
      ),
    );
  }

  Widget _buildWidget(ThemeProvider themeProvider, Size size, bool isDragging) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(isDragging ? 0.8 : 0.7),
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
      child: Column(
        children: [
          // Widget header with title and resize/close buttons
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForWidgetType(widget.widget.type),
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.widget.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showWidgetOptions(context),
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Widget content
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: widget.widget.buildWidget(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForWidgetType(WidgetType type) {
    switch (type) {
      case WidgetType.clock:
        return Icons.access_time;
      case WidgetType.weather:
        return Icons.cloud;
      case WidgetType.calendar:
        return Icons.calendar_today;
      case WidgetType.notes:
        return Icons.note;
      case WidgetType.photo:
        return Icons.photo;
      case WidgetType.battery:
        return Icons.battery_charging_full;
      case WidgetType.custom:
        return Icons.widgets;
      default:
        return Icons.widgets;
    }
  }

  void _createDragOverlay(ThemeProvider themeProvider) {
    final overlay = Overlay.of(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final widgetSize = _getWidgetSize(context);

    _lastSnapPosition = position;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final statusBarHeight = MediaQuery.of(context).padding.top;

        final snappedPosition = _getSnappedPosition(
          _dragPosition,
          statusBarHeight,
        );

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
            child: _buildWidget(themeProvider, widgetSize, true),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _updateOverlayPosition() {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final newSnappedPosition = _getSnappedPosition(
      _dragPosition,
      statusBarHeight,
    );

    if ((newSnappedPosition - _lastSnapPosition).distance > 10) {
      _animationController.reset();
      _animationController.forward();

      _overlayEntry?.markNeedsBuild();

      if (_animation.value >= 0.9) {
        _lastSnapPosition = newSnappedPosition;
      }
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  Offset _getSnappedPosition(Offset rawOffset, double statusBarHeight) {
    final widgetSize = _getWidgetSize(context);

    // Calculate position adjusting for widget center and status bar
    final adjustedOffset = Offset(
      rawOffset.dx - (widgetSize.width / 2),
      rawOffset.dy - (widgetSize.height / 2) - statusBarHeight,
    );

    // Get a grid-snapped position
    final snappedPosition = GridCalculator.getGridPosition(
      context,
      adjustedOffset,
    );

    // Apply boundaries
    final screenSize = MediaQuery.of(context).size;

    final minX = GridCalculator.horizontalPadding;
    final minY = GridCalculator.verticalPadding;
    final maxX =
        screenSize.width - GridCalculator.horizontalPadding - widgetSize.width;
    final maxY =
        screenSize.height - GridCalculator.verticalPadding - widgetSize.height;

    final boundedX = snappedPosition.dx.clamp(minX, maxX);
    final boundedY = snappedPosition.dy.clamp(minY, maxY);

    return Offset(boundedX, boundedY);
  }

  void _showWidgetOptions(BuildContext context) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(_getIconForWidgetType(widget.widget.type)),
                title: Text(widget.widget.name),
                subtitle: Text(widget.widget.type.toString().split('.').last),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit widget'),
                onTap: () {
                  Navigator.pop(context);
                  _showWidgetEditor(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove widget'),
                onTap: () {
                  widgetProvider.removeWidget(widget.widget.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _showWidgetEditor(BuildContext context) {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);

    // Simple implementation for now
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit ${widget.widget.name}'),
            content: const Text('Widget editing options will go here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Handle save changes
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
