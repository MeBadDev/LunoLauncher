import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';

class AppProvider with ChangeNotifier {
  List<AppModel> _apps = [];
  List<AppModel> _filteredApps = [];
  String _searchQuery = '';
  String? _wallpaperPath;
  final List<String> _categories = [
    'Favorites',
    'Social',
    'Productivity',
    'Entertainment',
    'Games',
    'Other',
  ];
  String _currentCategory = 'Favorites';

  List<AppModel> get apps => _apps;
  List<AppModel> get filteredApps => _filteredApps;
  String get searchQuery => _searchQuery;
  List<String> get categories => _categories;
  String get currentCategory => _currentCategory;
  String? get wallpaperPath => _wallpaperPath;

  AppProvider() {
    loadApps();
    _loadWallpaperPath();
  }

  Future<void> loadApps() async {
    _apps = await AppModel.getInstalledApps();
    _loadFavorites();
    _loadCategories();
    _filterApps();
    notifyListeners();
  }

  Future<void> _loadWallpaperPath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _wallpaperPath = prefs.getString('wallpaper_path');
    notifyListeners();
  }

  Future<void> setWallpaperPath(String? path) async {
    _wallpaperPath = path;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('wallpaper_path', path);
    } else {
      await prefs.remove('wallpaper_path');
    }
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList('favorites') ?? [];

    for (var app in _apps) {
      app.isFavorite = favorites.contains(app.packageName);
    }
  }

  Future<void> _loadCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var app in _apps) {
      String savedCategory =
          prefs.getString('category_${app.packageName}') ?? 'Other';
      if (_categories.contains(savedCategory)) {
        app.category = savedCategory;
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterApps();
    notifyListeners();
  }

  void setCurrentCategory(String category) {
    _currentCategory = category;
    _filterApps();
    notifyListeners();
  }

  Future<void> toggleFavorite(AppModel app) async {
    app.isFavorite = !app.isFavorite;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];

    if (app.isFavorite) {
      favorites.add(app.packageName);
    } else {
      favorites.remove(app.packageName);
    }

    await prefs.setStringList('favorites', favorites);
    _filterApps();
    notifyListeners();
  }

  Future<void> setAppCategory(AppModel app, String category) async {
    app.category = category;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_${app.packageName}', category);
    _filterApps();
    notifyListeners();
  }

  void _filterApps() {
    if (_searchQuery.isEmpty) {
      if (_currentCategory == 'Favorites') {
        _filteredApps = _apps.where((app) => app.isFavorite).toList();
      } else {
        _filteredApps =
            _apps.where((app) => app.category == _currentCategory).toList();
      }
    } else {
      _filteredApps =
          _apps
              .where(
                (app) =>
                    app.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
    }
  }
}
