import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _maxQueryTabs = 12;

final NotifierProvider<_QueryPanelStateNotifier, _QueryPanelState>
_queryPanelProvider =
    NotifierProvider<_QueryPanelStateNotifier, _QueryPanelState>(
      _QueryPanelStateNotifier.new,
    );

class _QueryPanelState {
  const _QueryPanelState({
    required this.tabs,
    required this.nextTabId,
    required this.activeTabId,
  });

  final List<_QueryEditorTab> tabs;
  final int nextTabId;
  final int activeTabId;

  _QueryEditorTab get activeTab {
    return tabs.firstWhere(
      (_QueryEditorTab tab) => tab.id == activeTabId,
      orElse: () => tabs.first,
    );
  }

  _QueryPanelState copyWith({
    List<_QueryEditorTab>? tabs,
    int? nextTabId,
    int? activeTabId,
  }) {
    return _QueryPanelState(
      tabs: tabs ?? this.tabs,
      nextTabId: nextTabId ?? this.nextTabId,
      activeTabId: activeTabId ?? this.activeTabId,
    );
  }
}

class _QueryPanelStateNotifier extends Notifier<_QueryPanelState> {
  @override
  _QueryPanelState build() {
    final _QueryEditorTab initialTab = _QueryEditorTab(
      id: 1,
      title: 'Query 1',
      controller: TextEditingController(),
      lastExecutedQuery: '',
    );

    ref.onDispose(() {
      for (final _QueryEditorTab tab in state.tabs) {
        tab.controller.dispose();
      }
    });

    return _QueryPanelState(
      tabs: <_QueryEditorTab>[initialTab],
      nextTabId: 1,
      activeTabId: 1,
    );
  }

  _QueryEditorTab addTab() {
    final int nextId = state.nextTabId + 1;
    final int nextNumber = state.tabs.length + 1;
    final _QueryEditorTab tab = _QueryEditorTab(
      id: nextId,
      title: 'Query $nextNumber',
      controller: TextEditingController(),
      lastExecutedQuery: '',
    );

    state = state.copyWith(
      tabs: <_QueryEditorTab>[...state.tabs, tab],
      nextTabId: nextId,
      activeTabId: tab.id,
    );
    return tab;
  }

  _QueryEditorTab? selectTab(int id) {
    final _QueryEditorTab? tab = _findById(id);
    if (tab == null) {
      return null;
    }
    state = state.copyWith(activeTabId: id);
    return tab;
  }

  _QueryEditorTab? closeTab(int id) {
    if (state.tabs.length <= 1) {
      return null;
    }

    final int closingIndex = state.tabs.indexWhere(
      (_QueryEditorTab tab) => tab.id == id,
    );
    if (closingIndex == -1) {
      return null;
    }

    final List<_QueryEditorTab> nextTabs = List<_QueryEditorTab>.of(state.tabs);
    final _QueryEditorTab closingTab = nextTabs.removeAt(closingIndex);
    closingTab.controller.dispose();

    int nextActiveId = state.activeTabId;
    if (state.activeTabId == id) {
      final int nextIndex = closingIndex >= nextTabs.length
          ? nextTabs.length - 1
          : closingIndex;
      nextActiveId = nextTabs[nextIndex].id;
    }

    state = state.copyWith(tabs: nextTabs, activeTabId: nextActiveId);
    return state.activeTab;
  }

  void renameTab(int id, String normalizedTitle) {
    final int index = state.tabs.indexWhere(
      (_QueryEditorTab tab) => tab.id == id,
    );
    if (index == -1) {
      return;
    }

    final List<_QueryEditorTab> nextTabs = List<_QueryEditorTab>.of(state.tabs);
    nextTabs[index] = nextTabs[index].copyWith(title: normalizedTitle);
    state = state.copyWith(tabs: nextTabs);
  }

  void setLastExecutedQuery(int id, String query) {
    final int index = state.tabs.indexWhere(
      (_QueryEditorTab tab) => tab.id == id,
    );
    if (index == -1) {
      return;
    }

    final List<_QueryEditorTab> nextTabs = List<_QueryEditorTab>.of(state.tabs);
    nextTabs[index] = nextTabs[index].copyWith(lastExecutedQuery: query);
    state = state.copyWith(tabs: nextTabs);
  }

  void clearLastExecutedQuery(int id) {
    setLastExecutedQuery(id, '');
  }

  _QueryEditorTab? _findById(int id) {
    for (final _QueryEditorTab tab in state.tabs) {
      if (tab.id == id) {
        return tab;
      }
    }
    return null;
  }
}

class HomeQueryPanel extends ConsumerWidget {
  const HomeQueryPanel({
    super.key,
    required this.onRunQuery,
    required this.onClearQuery,
    required this.onActivateTabQuery,
    required this.onOpenFile,
    required this.onOpenSettings,
    required this.dataSourceLabel,
    required this.loadError,
    required this.queryValidationError,
    required this.isQueryRunning,
  });

  final void Function(int tabId, String query) onRunQuery;
  final ValueChanged<int> onClearQuery;
  final void Function(int tabId, String query) onActivateTabQuery;
  final VoidCallback onOpenFile;
  final VoidCallback onOpenSettings;
  final String dataSourceLabel;
  final String? loadError;
  final String? queryValidationError;
  final bool isQueryRunning;

  void _addTab(WidgetRef ref) {
    if (isQueryRunning) {
      return;
    }

    final _QueryPanelState state = ref.read(_queryPanelProvider);
    if (state.tabs.length >= _maxQueryTabs) {
      return;
    }

    final _QueryEditorTab tab = ref.read(_queryPanelProvider.notifier).addTab();
    onActivateTabQuery(tab.id, '');
  }

  void _selectTab(WidgetRef ref, int id) {
    if (isQueryRunning) {
      return;
    }

    final _QueryEditorTab? tab = ref
        .read(_queryPanelProvider.notifier)
        .selectTab(id);
    if (tab == null) {
      return;
    }
    onActivateTabQuery(tab.id, tab.lastExecutedQuery);
  }

  void _closeTab(WidgetRef ref, int id) {
    if (isQueryRunning) {
      return;
    }

    final _QueryPanelState state = ref.read(_queryPanelProvider);
    if (state.tabs.length <= 1) {
      return;
    }

    final _QueryEditorTab? active = ref
        .read(_queryPanelProvider.notifier)
        .closeTab(id);
    if (active == null) {
      return;
    }
    onActivateTabQuery(active.id, active.lastExecutedQuery);
  }

  Future<void> _renameTab(BuildContext context, WidgetRef ref, int id) async {
    if (isQueryRunning) {
      return;
    }

    final _QueryPanelState state = ref.read(_queryPanelProvider);
    final _QueryEditorTab? tab = state.tabs.cast<_QueryEditorTab?>().firstWhere(
      (_QueryEditorTab? t) => t?.id == id,
      orElse: () => null,
    );
    if (tab == null) {
      return;
    }

    final TextEditingController renameController = TextEditingController(
      text: tab.title,
    );

    final String? newTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Query Tab'),
          content: TextField(
            controller: renameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Query name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onSubmitted: (String value) {
              Navigator.of(context).pop(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(renameController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    renameController.dispose();
    if (!context.mounted || newTitle == null) {
      return;
    }

    final String normalized = newTitle.trim();
    if (normalized.isEmpty) {
      return;
    }

    ref.read(_queryPanelProvider.notifier).renameTab(id, normalized);
  }

  void _runActiveQuery(WidgetRef ref, _QueryPanelState state) {
    final _QueryEditorTab activeTab = state.activeTab;
    final String text = activeTab.controller.text;
    ref
        .read(_queryPanelProvider.notifier)
        .setLastExecutedQuery(activeTab.id, text);
    onRunQuery(activeTab.id, text);
  }

  void _clearActiveQuery(WidgetRef ref, _QueryPanelState state) {
    final _QueryEditorTab activeTab = state.activeTab;
    ref.read(_queryPanelProvider.notifier).clearLastExecutedQuery(activeTab.id);
    activeTab.controller.clear();
    onClearQuery(activeTab.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _QueryPanelState panelState = ref.watch(_queryPanelProvider);
    final _QueryEditorTab activeTab = panelState.activeTab;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo_gony3t.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Query Section', style: TextStyle(fontSize: 16)),
              const Spacer(),
              IconButton(
                tooltip: 'Open .realm file',
                onPressed: onOpenFile,
                icon: const Icon(Icons.folder_open),
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Settings',
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Data source: $dataSourceLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (loadError != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              loadError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: panelState.tabs.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == panelState.tabs.length) {
                  return IconButton(
                    tooltip: 'Add query tab',
                    onPressed:
                        isQueryRunning ||
                            panelState.tabs.length >= _maxQueryTabs
                        ? null
                        : () => _addTab(ref),
                    icon: const Icon(Icons.add),
                  );
                }

                final _QueryEditorTab tab = panelState.tabs[index];
                final bool isActive = tab.id == panelState.activeTabId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onLongPress: () => _renameTab(context, ref, tab.id),
                    child: InputChip(
                      selected: isActive,
                      label: Text(tab.title),
                      onSelected: (_) => _selectTab(ref, tab.id),
                      onDeleted: panelState.tabs.length > 1
                          ? () => _closeTab(ref, tab.id)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: ValueKey<int>(activeTab.id),
                  controller: activeTab.controller,
                  enabled: !isQueryRunning,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    hintText: 'Try: name:alice && age>=30 && status=active',
                    prefixIcon: Icon(Icons.query_stats),
                  ),
                  onSubmitted: (_) => _runActiveQuery(ref, panelState),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: isQueryRunning
                    ? null
                    : () => _runActiveQuery(ref, panelState),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isQueryRunning
                    ? null
                    : () => _clearActiveQuery(ref, panelState),
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
          if (isQueryRunning) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: const <Widget>[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Running query on full dataset...'),
              ],
            ),
          ],
          if (queryValidationError != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              queryValidationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueryEditorTab {
  const _QueryEditorTab({
    required this.id,
    required this.title,
    required this.controller,
    required this.lastExecutedQuery,
  });

  final int id;
  final String title;
  final TextEditingController controller;
  final String lastExecutedQuery;

  _QueryEditorTab copyWith({
    int? id,
    String? title,
    TextEditingController? controller,
    String? lastExecutedQuery,
  }) {
    return _QueryEditorTab(
      id: id ?? this.id,
      title: title ?? this.title,
      controller: controller ?? this.controller,
      lastExecutedQuery: lastExecutedQuery ?? this.lastExecutedQuery,
    );
  }
}
