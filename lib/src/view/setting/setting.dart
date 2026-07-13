import 'package:flutter/material.dart';
import 'package:realm_gony3t/src/utils/contant.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static const String routeName = '$initRoute/setting';

  @override
  Widget build(BuildContext context) {
    final Map<ThemeMode, String> labels = <ThemeMode, String>{
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light mode',
      ThemeMode.dark: 'Dark mode',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 8),
          const ListTile(
            title: Text('Theme mode'),
            subtitle: Text('Choose app appearance behavior'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: labels.entries
                  .map(
                    (MapEntry<ThemeMode, String> entry) =>
                        ButtonSegment<ThemeMode>(
                          value: entry.key,
                          label: Text(entry.value),
                        ),
                  )
                  .toList(),
              selected: <ThemeMode>{currentThemeMode},
              showSelectedIcon: false,
              onSelectionChanged: (Set<ThemeMode> selection) {
                onThemeModeChanged(selection.first);
              },
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Current mode'),
            subtitle: Text(labels[currentThemeMode] ?? 'Unknown'),
          ),
        ],
      ),
    );
  }
}
