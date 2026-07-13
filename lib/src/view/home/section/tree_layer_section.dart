import 'package:flutter/material.dart';
import 'package:realm_gony3t/realm_gony3T.dart';

class HomeMobileBody extends StatelessWidget {
  const HomeMobileBody({
    super.key,
    required this.classes,
    required this.documents,
    required this.tableColumns,
    required this.selectedIndex,
    required this.dataSourceLabel,
    required this.schemaName,
    required this.onSelectClass,
  });

  final List<RealmClassSummary> classes;
  final List<Map<String, dynamic>> documents;
  final List<String> tableColumns;
  final int selectedIndex;
  final String dataSourceLabel;
  final String? schemaName;
  final ValueChanged<String> onSelectClass;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          const TabBar(
            tabs: <Tab>[
              Tab(text: 'Layer'),
              Tab(text: 'JSON'),
              Tab(text: 'Table'),
              Tab(text: 'Inspector'),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                HomeTreeLayerPanel(
                  classes: classes,
                  documents: documents,
                  selectedIndex: selectedIndex,
                  dataSourceLabel: dataSourceLabel,
                  schemaName: schemaName,
                  onSelectClass: onSelectClass,
                ),
                HomeJsonView(documents: documents),
                HomeTableView(documents: documents, columns: tableColumns),
                HomeInspectorView(documents: documents),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTreeLayerPanel extends StatelessWidget {
  const HomeTreeLayerPanel({
    super.key,
    required this.classes,
    required this.documents,
    required this.selectedIndex,
    required this.dataSourceLabel,
    required this.schemaName,
    required this.onSelectClass,
  });

  final List<RealmClassSummary> classes;
  final List<Map<String, dynamic>> documents;
  final int selectedIndex;
  final String dataSourceLabel;
  final String? schemaName;
  final ValueChanged<String> onSelectClass;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color selectedColor = theme.colorScheme.primary.withValues(
      alpha: 0.18,
    );
    final Color selectedBorderColor = theme.colorScheme.primary;
    final Color selectedTextColor = theme.colorScheme.primary;
    final String selectedClass = schemaName ?? '';
    final Color bg = theme.colorScheme.surface;

    return ColoredBox(
      color: bg,
      child: ClipRect(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: <Widget>[
            const ListTile(dense: true, title: Text('CLASSES')),
            ListTile(
              dense: true,
              leading: const Icon(Icons.link, size: 18),
              title: Text(dataSourceLabel),
            ),
            if (classes.isEmpty)
              const ListTile(dense: true, title: Text('No classes found')),
            ...classes.map((RealmClassSummary item) {
              final bool isSelected = item.name == selectedClass;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isSelected
                      ? BorderSide(color: selectedBorderColor, width: 1.2)
                      : BorderSide.none,
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? selectedTextColor : null,
                  ),
                ),
                trailing: HomeCountBadge(
                  count: item.count,
                  isSelected: isSelected,
                ),
                onTap: () => onSelectClass(item.name),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class HomeCountBadge extends StatelessWidget {
  const HomeCountBadge({
    super.key,
    required this.count,
    this.isSelected = false,
  });

  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '$count',
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : null,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
