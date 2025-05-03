import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Enum to represent different types of widgets available
enum WidgetType { clock, weather, calendar, notes, photo, battery, custom }

// Base class for all widgets
class WidgetModel {
  final String id; // Unique identifier for the widget
  final String name; // Display name
  final WidgetType type; // Type of widget
  final int width; // Width in grid units
  final int height; // Height in grid units
  final Map<String, dynamic> settings; // Widget-specific settings

  WidgetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.width,
    required this.height,
    this.settings = const {},
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'width': width,
      'height': height,
      'settings': settings,
    };
  }

  // Create from JSON data
  factory WidgetModel.fromJson(Map<String, dynamic> json) {
    return WidgetModel(
      id: json['id'],
      name: json['name'],
      type: WidgetType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => WidgetType.custom,
      ),
      width: json['width'],
      height: json['height'],
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  // Create appropriate widget instance based on type
  Widget buildWidget() {
    switch (type) {
      case WidgetType.clock:
        return ClockWidgetContent(settings: settings);
      case WidgetType.weather:
        return WeatherWidgetContent(settings: settings);
      case WidgetType.calendar:
        return CalendarWidgetContent(settings: settings);
      case WidgetType.notes:
        return NotesWidgetContent(settings: settings);
      case WidgetType.photo:
        return PhotoWidgetContent(settings: settings);
      case WidgetType.battery:
        return BatteryWidgetContent(settings: settings);
      case WidgetType.custom:
        return CustomWidgetContent(settings: settings);
      default:
        return const SizedBox(); // Fallback
    }
  }

  // Create a copy with updated fields
  WidgetModel copyWith({
    String? id,
    String? name,
    WidgetType? type,
    int? width,
    int? height,
    Map<String, dynamic>? settings,
  }) {
    return WidgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      width: width ?? this.width,
      height: height ?? this.height,
      settings: settings ?? Map<String, dynamic>.from(this.settings),
    );
  }
}

// Widget content classes
class ClockWidgetContent extends StatelessWidget {
  final Map<String, dynamic> settings;

  const ClockWidgetContent({Key? key, required this.settings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 32),
          Text(
            '12:34',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('Monday, May 3'),
        ],
      ),
    );
  }
}

class WeatherWidgetContent extends StatelessWidget {
  final Map<String, dynamic> settings;

  const WeatherWidgetContent({Key? key, required this.settings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud, size: 32),
          Text(
            '72°F',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('Partly Cloudy'),
        ],
      ),
    );
  }
}

class CalendarWidgetContent extends StatelessWidget {
  final Map<String, dynamic> settings;

  const CalendarWidgetContent({Key? key, required this.settings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 32),
          Text('No events today', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class NotesWidgetContent extends StatelessWidget {
  final Map<String, dynamic> settings;

  const NotesWidgetContent({Key? key, required this.settings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    String noteText = settings['text'] ?? 'Tap to add a note';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note, size: 24),
          const SizedBox(height: 8),
          Text(
            noteText,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class PhotoWidgetContent extends StatelessWidget {
  final Map<String, dynamic> settings;

  const PhotoWidgetContent({Key? key, required this.settings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          settings['imagePath'] != null
              ? Image.asset(settings['imagePath'])
              : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo, size: 32),
                  Text('No photo selected'),
                ],
              ),
    );
  }
}

class BatteryWidgetContent extends StatelessWidget {
  final Map<String, dynamic> settings;

  const BatteryWidgetContent({Key? key, required this.settings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In a real app, you would get actual battery level
    int batteryLevel = 75;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.battery_charging_full, size: 32),
          Text(
            '$batteryLevel%',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class CustomWidgetContent extends StatelessWidget {
  final Map<String, dynamic> settings;

  const CustomWidgetContent({Key? key, required this.settings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Custom Widget'));
  }
}
