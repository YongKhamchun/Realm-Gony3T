import 'package:flutter/material.dart';

class HomeQueryPanel extends StatefulWidget {
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

  @override
  State<HomeQueryPanel> createState() => _HomeQueryPanelState();
}

class _HomeQueryPanelState extends State<HomeQueryPanel> {
  static const int _maxTabs = 12;

  final List<_QueryEditorTab> _tabs = <_QueryEditorTab>[];
  int _nextTabId = 1;
  int _activeTabId = 1;

  _QueryEditorTab get _activeTab {
    return _tabs.firstWhere(
      (_QueryEditorTab tab) => tab.id == _activeTabId,
      orElse: () => _tabs.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabs.add(
      _QueryEditorTab(
        id: _nextTabId,
        title: 'Query 1',
        controller: TextEditingController(),
        lastExecutedQuery: '',
      ),
    );
  }

  @override
  void dispose() {
    for (final _QueryEditorTab tab in _tabs) {
      tab.controller.dispose();
    }
    super.dispose();
  }

  void _addTab() {
    if (widget.isQueryRunning || _tabs.length >= _maxTabs) {
      return;
    }

    setState(() {
      _nextTabId += 1;
      final int nextNumber = _tabs.length + 1;
      final _QueryEditorTab tab = _QueryEditorTab(
        id: _nextTabId,
        title: 'Query $nextNumber',
        controller: TextEditingController(),
        lastExecutedQuery: '',
      );
      _tabs.add(tab);
      _activeTabId = tab.id;
    });

    widget.onActivateTabQuery(_activeTabId, '');
  }

  void _selectTab(int id) {
    if (widget.isQueryRunning) {
      return;
    }
    setState(() {
      _activeTabId = id;
    });

    final _QueryEditorTab tab = _tabs.firstWhere(
      (_QueryEditorTab t) => t.id == id,
    );
    widget.onActivateTabQuery(tab.id, tab.lastExecutedQuery);
  }

  void _closeTab(int id) {
    if (widget.isQueryRunning || _tabs.length <= 1) {
      return;
    }

    final int closingIndex = _tabs.indexWhere(
      (_QueryEditorTab tab) => tab.id == id,
    );
    if (closingIndex == -1) {
      return;
    }

    setState(() {
      final _QueryEditorTab closingTab = _tabs.removeAt(closingIndex);
      closingTab.controller.dispose();

      if (_activeTabId == id) {
        final int nextIndex = closingIndex >= _tabs.length
            ? _tabs.length - 1
            : closingIndex;
        _activeTabId = _tabs[nextIndex].id;
      }
    });

    widget.onActivateTabQuery(_activeTab.id, _activeTab.lastExecutedQuery);
  }

  Future<void> _renameTab(int id) async {
    if (widget.isQueryRunning) {
      return;
    }

    final int index = _tabs.indexWhere((_QueryEditorTab tab) => tab.id == id);
    if (index == -1) {
      return;
    }

    final TextEditingController renameController = TextEditingController(
      text: _tabs[index].title,
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
    if (!mounted || newTitle == null) {
      return;
    }

    final String normalized = newTitle.trim();
    if (normalized.isEmpty) {
      return;
    }

    setState(() {
      _tabs[index] = _tabs[index].copyWith(title: normalized);
    });
  }

  void _runActiveQuery() {
    final String text = _activeTab.controller.text;
    final int index = _tabs.indexWhere(
      (_QueryEditorTab tab) => tab.id == _activeTabId,
    );
    if (index >= 0) {
      setState(() {
        _tabs[index] = _tabs[index].copyWith(lastExecutedQuery: text);
      });
    }
    widget.onRunQuery(_activeTabId, text);
  }

  void _clearActiveQuery() {
    final int index = _tabs.indexWhere(
      (_QueryEditorTab tab) => tab.id == _activeTabId,
    );
    if (index >= 0) {
      setState(() {
        _tabs[index] = _tabs[index].copyWith(lastExecutedQuery: '');
      });
    }
    _activeTab.controller.clear();
    widget.onClearQuery(_activeTabId);
  }

  @override
  Widget build(BuildContext context) {
    final _QueryEditorTab activeTab = _activeTab;

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
                onPressed: widget.onOpenFile,
                icon: const Icon(Icons.folder_open),
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Settings',
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Data source: ${widget.dataSourceLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.loadError != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.loadError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                ..._tabs.map((_QueryEditorTab tab) {
                  final bool isActive = tab.id == _activeTabId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onLongPress: () => _renameTab(tab.id),
                      child: InputChip(
                        selected: isActive,
                        label: Text(tab.title),
                        onSelected: (_) => _selectTab(tab.id),
                        onDeleted: _tabs.length > 1
                            ? () => _closeTab(tab.id)
                            : null,
                      ),
                    ),
                  );
                }),
                IconButton(
                  tooltip: 'Add query tab',
                  onPressed: widget.isQueryRunning || _tabs.length >= _maxTabs
                      ? null
                      : _addTab,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: ValueKey<int>(activeTab.id),
                  controller: activeTab.controller,
                  enabled: !widget.isQueryRunning,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    hintText: 'Try: name:alice && age>=30 && status=active',
                    prefixIcon: Icon(Icons.query_stats),
                  ),
                  onSubmitted: (_) => _runActiveQuery(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: widget.isQueryRunning ? null : _runActiveQuery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.isQueryRunning ? null : _clearActiveQuery,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
          if (widget.isQueryRunning) ...<Widget>[
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
          if (widget.queryValidationError != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.queryValidationError!,
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
