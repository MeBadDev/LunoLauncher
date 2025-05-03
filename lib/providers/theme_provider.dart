import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = Colors.indigo;
  bool _useBlur = true;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get useBlur => _useBlur;

  ThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode =
        prefs.getString('themeMode') == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light;
    _accentColor = Color(
      prefs.getInt('accentColor') ?? Colors.indigo.toARGB32(),
    );
    _useBlur = prefs.getBool('useBlur') ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'themeMode',
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
      notifyListeners();
    }
  }

  Future<void> setAccentColor(Color color) async {
    if (_accentColor != color) {
      _accentColor = color;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accentColor', color.toARGB32());
      notifyListeners();
    }
  }

  Future<void> toggleBlur() async {
    _useBlur = !_useBlur;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useBlur', _useBlur);
    notifyListeners();
  }

  ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _accentColor,
      colorScheme: ColorScheme.light(primary: _accentColor),
      fontFamily: GoogleFonts.poppins().fontFamily,
      useMaterial3: true,
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _accentColor,
      colorScheme: ColorScheme.dark(primary: _accentColor),
      fontFamily: GoogleFonts.poppins().fontFamily,
      useMaterial3: true,
    );
  }
}
