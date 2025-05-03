import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WallpaperService {
  static const platform = MethodChannel('net.mebaddev.lunolauncher/wallpaper');

  /// Retrieves the device's current wallpaper as an ImageProvider
  /// Returns null if unable to retrieve the wallpaper
  static Future<ImageProvider?> getSystemWallpaper() async {
    try {
      print('Attempting to get system wallpaper...');
      final Uint8List? result = await platform.invokeMethod('getWallpaper');
      if (result != null) {
        print('Wallpaper retrieved successfully, size: ${result.length} bytes');
        return MemoryImage(result);
      } else {
        print('Failed to get wallpaper: result was null');
      }
    } on PlatformException catch (e) {
      print(
        'Platform Exception when getting wallpaper: ${e.message}, ${e.details}',
      );
    } catch (e) {
      print('Error getting system wallpaper: ${e.toString()}');
    }
    return null;
  }
}
