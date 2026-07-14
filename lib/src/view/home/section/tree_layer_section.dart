import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm_gony3t/realm_gony3t.dart';

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

class HomeTreeLayerPanel extends ConsumerStatefulWidget {
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
  ConsumerState<HomeTreeLayerPanel> createState() => _HomeTreeLayerPanelState();
}

class _HomeTreeLayerPanelState extends ConsumerState<HomeTreeLayerPanel> {
  final TextEditingController _classSearchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String query = ref.read(homeProvider).classSearchQuery;
    if (_classSearchController.text != query) {
      _classSearchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _classSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeState state = ref.watch(homeProvider);
    final ThemeData theme = Theme.of(context);
    final Color selectedColor = theme.colorScheme.primary.withValues(
      alpha: 0.18,
    );
    final Color selectedBorderColor = theme.colorScheme.primary;
    final Color selectedTextColor = theme.colorScheme.primary;
    final String selectedClass = widget.schemaName ?? '';
    final Color bg = theme.colorScheme.surface;
    final String search = state.classSearchQuery.trim().toLowerCase();
    final List<RealmClassSummary> filteredClasses = search.isEmpty
        ? widget.classes
        : widget.classes
              .where(
                (RealmClassSummary item) =>
                    item.name.toLowerCase().contains(search),
              )
              .toList(growable: false);

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
              title: Text(widget.dataSourceLabel),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _classSearchController,
                decoration: const InputDecoration(
                  hintText: 'Find class',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (String value) {
                  ref.read(homeProvider.notifier).updateClassSearchQuery(value);
                },
              ),
            ),
            if (filteredClasses.isEmpty)
              const ListTile(dense: true, title: Text('No classes found')),
            ...filteredClasses.map((RealmClassSummary item) {
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
                onTap: () => widget.onSelectClass(item.name),
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
