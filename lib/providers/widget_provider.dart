import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/widget_model.dart';

class WidgetProvider with ChangeNotifier {
  List<WidgetModel> _widgets = [];
  Map<String, Offset> _widgetPositions = {};
  final uuid = const Uuid();

  List<WidgetModel> get widgets => _widgets;

  // Get a widget's position by ID
  Offset getWidgetPosition(String id) {
    return _widgetPositions[id] ?? const Offset(0, 0);
  }

  // Initialize provider by loading widgets from shared preferences
  Future<void> loadWidgets() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Load widgets
      final widgetsJson = prefs.getStringList('widgets') ?? [];
      _widgets =
          widgetsJson
              .map((json) => WidgetModel.fromJson(jsonDecode(json)))
              .toList();

      // Load widget positions
      for (var widget in _widgets) {
        final x = prefs.getDouble('widget_${widget.id}_x');
        final y = prefs.getDouble('widget_${widget.id}_y');
        if (x != null && y != null) {
          _widgetPositions[widget.id] = Offset(x, y);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading widgets: $e');
      // Reset if there's an error
      _widgets = [];
    }
  }

  // Save all widgets to shared preferences
  Future<void> _saveWidgets() async {
    final prefs = await SharedPreferences.getInstance();
    final widgetsJson = _widgets.map((w) => jsonEncode(w.toJson())).toList();
    await prefs.setStringList('widgets', widgetsJson);
  }

  // Save a widget's position
  Future<void> saveWidgetPosition(String id, Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    _widgetPositions[id] = position;
    await prefs.setDouble('widget_${id}_x', position.dx);
    await prefs.setDouble('widget_${id}_y', position.dy);
  }

  // Add a new widget
  Future<void> addWidget(
    WidgetType type, {
    Map<String, dynamic>? settings,
    String? name,
  }) async {
    // Set default width and height based on widget type
    int width = 2; // Default width in grid cells
    int height = 2; // Default height in grid cells

    // Adjust size based on widget type
    switch (type) {
      case WidgetType.clock:
        width = 2;
        height = 1;
        break;
      case WidgetType.weather:
        width = 2;
        height = 2;
        break;
      case WidgetType.calendar:
        width = 4;
        height = 2;
        break;
      case WidgetType.notes:
        width = 2;
        height = 3;
        break;
      case WidgetType.photo:
        width = 2;
        height = 2;
        break;
      case WidgetType.battery:
        width = 1;
        height = 1;
        break;
      default:
        break;
    }

    // Generate default name if not provided
    name ??= type.toString().split('.').last.capitalize();

    // Create the new widget
    final widget = WidgetModel(
      id: uuid.v4(),
      name: name,
      type: type,
      width: width,
      height: height,
      settings: settings ?? {},
    );

    // Add to list and save
    _widgets.add(widget);
    await _saveWidgets();
    notifyListeners();
  }

  // Update an existing widget
  Future<void> updateWidget(
    String id, {
    String? name,
    Map<String, dynamic>? settings,
    int? width,
    int? height,
  }) async {
    final index = _widgets.indexWhere((w) => w.id == id);
    if (index >= 0) {
      _widgets[index] = _widgets[index].copyWith(
        name: name,
        settings: settings,
        width: width,
        height: height,
      );

      await _saveWidgets();
      notifyListeners();
    }
  }

  // Remove a widget
  Future<void> removeWidget(String id) async {
    _widgets.removeWhere((w) => w.id == id);
    _widgetPositions.remove(id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('widget_${id}_x');
    await prefs.remove('widget_${id}_y');

    await _saveWidgets();
    notifyListeners();
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
