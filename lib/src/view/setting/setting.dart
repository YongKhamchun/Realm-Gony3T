import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm_gony3t/realm_gony3t.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  static const String routeName = '$initRoute/setting-page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode currentThemeMode = ref.watch(themeModeProvider);
    final Map<ThemeMode, String> labels = <ThemeMode, String>{
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light mode',
      ThemeMode.dark: 'Dark mode',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              // final ThemeMode mode = ThemeMode.values[index];
              return Column(
                children: [
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
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(selection.first);
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
              );
            }, childCount: 1),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gony3T v0.1.0+3 alpha', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text(
                '© 2026 Gony3T. All rights reserved. by Natthanon Khamchun',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
