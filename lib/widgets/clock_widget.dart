import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => ClockWidgetState();
}

class ClockWidgetState extends State<ClockWidget> {
  late String _timeString;
  late String _dateString;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update time every second
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = DateFormat('HH:mm').format(now);

    // Use a shorter date format to prevent overflow
    final String formattedDate = DateFormat('EEE, MMM d').format(now);

    setState(() {
      _timeString = formattedTime;
      _dateString = formattedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the available width
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust text size based on screen width
    final timeTextSize = screenWidth * 0.15; // 15% of screen width
    final dateTextSize = screenWidth * 0.04; // 4% of screen width

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        width: screenWidth * 0.9, // 90% of screen width
        constraints: BoxConstraints(
          maxWidth: screenWidth - 32, // Account for padding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _timeString,
              style: TextStyle(
                fontSize: timeTextSize,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _dateString,
              style: TextStyle(
                fontSize: dateTextSize,
                fontWeight: FontWeight.w300,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
