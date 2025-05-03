import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WallpaperService {
  static const platform = MethodChannel('net.mebaddev.lunolauncher/wallpaper');

  /// Requests the necessary storage permissions based on Android SDK version
  static Future<bool> requestStoragePermissions() async {
    // Get Android SDK version to determine which permissions to request
    final sdkInt =
        await platform.invokeMethod<int>('getAndroidSdkVersion') ?? 0;

    // For Android 13+ (API 33+), we need READ_MEDIA_IMAGES
    // For Android 12 and below, we need READ_EXTERNAL_STORAGE
    List<Permission> permissions = [];

    if (sdkInt >= 33) {
      permissions.add(Permission.photos);
      permissions.add(Permission.mediaLibrary);
    } else {
      permissions.add(Permission.storage);
    }

    // Check and request all relevant permissions
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Log the status of each permission for debugging
    statuses.forEach((permission, status) {
      print('Permission $permission status: $status');
    });

    // Check if the necessary permission is granted based on SDK version
    if (sdkInt >= 33) {
      return statuses[Permission.photos]?.isGranted == true ||
          statuses[Permission.mediaLibrary]?.isGranted == true;
    } else {
      return statuses[Permission.storage]?.isGranted == true;
    }
  }

  /// Retrieves the device's current wallpaper as an ImageProvider
  /// Returns null if unable to retrieve the wallpaper
  static Future<ImageProvider?> getSystemWallpaper() async {
    try {
      print('Attempting to get system wallpaper...');

      // First ensure we have the necessary permissions
      bool hasPermission = await requestStoragePermissions();

      if (!hasPermission) {
        print('Storage permission denied');
        return null;
      }

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
