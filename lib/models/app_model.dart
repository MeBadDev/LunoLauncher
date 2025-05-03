import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppModel {
  final String name;
  final String packageName;
  final Widget icon;
  final bool isSystemApp;
  final Function() launchFunction;
  bool isFavorite;
  String category;

  AppModel({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.isSystemApp,
    required this.launchFunction,
    this.isFavorite = false,
    this.category = 'Other',
  });

  static Future<List<AppModel>> getInstalledApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true, "");
    List<AppModel> appModels = [];

    for (var app in apps) {
      // Get detailed app info which includes the app icon
      AppInfo? appInfo = await InstalledApps.getAppInfo(
        app.packageName,
        BuiltWith.native_or_others,
      );

      // Only add the app if we could get its info
      if (appInfo != null && appInfo.icon != null) {
        appModels.add(
          AppModel(
            name: app.name,
            packageName: app.packageName,
            icon: Image.memory(appInfo.icon!, width: 48, height: 48),
            isSystemApp:
                false, // InstalledApps doesn't provide this info directly
            launchFunction: () => InstalledApps.startApp(app.packageName),
          ),
        );
      }
    }

    return appModels;
  }
}
