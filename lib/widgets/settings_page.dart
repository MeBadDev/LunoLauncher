import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/app_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        children: [
          // Home Screen section
          const ListTile(
            title: Text(
              'HOME SCREEN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            dense: true,
          ),
          ListTile(
            title: const Text('Wallpaper'),
            subtitle: Text(
              appProvider.wallpaperPath != null
                  ? 'Custom wallpaper selected'
                  : 'Default gradient background',
            ),
            leading: const Icon(Icons.wallpaper),
            onTap: () => _showWallpaperOptions(context, appProvider),
          ),
          const Divider(),

          // Appearance section
          const ListTile(
            title: Text(
              'APPEARANCE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            dense: true,
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Change app appearance'),
            leading: const Icon(Icons.palette),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                themeProvider.setThemeMode(selection.first);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Visual Effects'),
            subtitle: const Text('Enable/disable blur and shadows'),
            leading: const Icon(Icons.auto_fix_high),
            trailing: Switch(
              value: themeProvider.useBlur,
              onChanged: (value) {
                themeProvider.toggleBlur();
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Accent Color'),
            subtitle: const Text('Pick your favorite accent color'),
            leading: const Icon(Icons.color_lens),
            trailing: _buildColorPicker(context, themeProvider),
          ),
          const Divider(),

          // About section
          const ListTile(
            title: Text('ABOUT', style: TextStyle(fontWeight: FontWeight.bold)),
            dense: true,
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('LunoLauncher v0.1.0'),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, ThemeProvider themeProvider) {
    final colors = [
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
    ];

    return InkWell(
      onTap: () => _showColorPickerDialog(context, colors, themeProvider),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: themeProvider.accentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    List<Color> colors,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Accent Color'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  colors.map((color) {
                    return InkWell(
                      onTap: () {
                        themeProvider.setAccentColor(color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                themeProvider.accentColor == color
                                    ? Theme.of(context).colorScheme.onSurface
                                    : color,
                            width: themeProvider.accentColor == color ? 2 : 0,
                          ),
                        ),
                        child:
                            themeProvider.accentColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showWallpaperOptions(BuildContext context, AppProvider appProvider) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_photo_alternate),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);

                  try {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1920,
                    );

                    if (image != null) {
                      appProvider.setWallpaperPath(image.path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Wallpaper updated')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error selecting image: $e')),
                      );
                    }
                  }
                },
              ),
              if (appProvider.wallpaperPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove wallpaper'),
                  onTap: () {
                    appProvider.setWallpaperPath(null);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wallpaper removed')),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
