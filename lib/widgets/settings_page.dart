import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        children: [
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
          const ListTile(
            title: Text('About'),
            subtitle: Text('Elegant Home Launcher v0.1.0'),
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
}
