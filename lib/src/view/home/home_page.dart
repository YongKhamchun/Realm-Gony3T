import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:realm_gony3t/realm_gony3T.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '$initRoute/home-page';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RealmUserRepository _repository = RealmUserRepository();
  final TextEditingController _queryController = TextEditingController();
  static const int _maxDisplayCount = 50;
  String _lastEncryptionKeyInput = '';

  List<Map<String, dynamic>> _documents = <Map<String, dynamic>>[
    <String, dynamic>{
      '_id': 'u001',
      'name': 'Alice',
      'status': 'active',
      'age': 28,
      'city': 'Bangkok',
    },
    <String, dynamic>{
      '_id': 'u002',
      'name': 'Bob',
      'status': 'inactive',
      'age': 34,
      'city': 'Chiang Mai',
    },
  ];

  String _query = '';
  int _pageStart = 0;
  int _selectedIndex = 0;
  String _dataSourceLabel = 'Mock data';
  List<RealmClassSummary> _classes = <RealmClassSummary>[];
  String? _openedSchemaName;
  String? _loadError;

  @override
  void dispose() {
    _repository.close();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _pickAndOpenRealmFile() async {
    String? filePath;

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['realm'],
        dialogTitle: 'Select .realm file',
      );
      filePath = result?.files.single.path;
    } catch (_) {
      filePath = await _showPathInputDialog();
    }

    if (!mounted || filePath == null || filePath.trim().isEmpty) {
      return;
    }

    final String? encryptionKeyInput = await _showEncryptionKeyDialog(
      initialValue: _lastEncryptionKeyInput,
    );

    if (!mounted || encryptionKeyInput == null) {
      return;
    }

    _lastEncryptionKeyInput = encryptionKeyInput;

    await _openRealmFile(
      filePath.trim(),
      encryptionKeyInput: encryptionKeyInput,
    );
  }

  Future<void> _openRealmFile(
    String filePath, {
    String? encryptionKeyInput,
  }) async {
    final File file = File(filePath);
    if (!file.existsSync()) {
      setState(() {
        _loadError = 'File not found: $filePath';
      });
      return;
    }

    try {
      final List<RealmClassSummary> classes = _repository.openAndListClasses(
        filePath,
        encryptionKeyInput: encryptionKeyInput,
      );

      final String? initialClassName = classes
          .cast<RealmClassSummary?>()
          .firstWhere(
            (RealmClassSummary? summary) => (summary?.count ?? 0) > 0,
            orElse: () => classes.isEmpty ? null : classes.first,
          )
          ?.name;

      final List<Map<String, dynamic>> loaded = initialClassName == null
          ? <Map<String, dynamic>>[]
          : _repository.readClassDocuments(initialClassName);

      setState(() {
        _classes = classes;
        _documents = loaded;
        _query = '';
        _pageStart = 0;
        _queryController.clear();
        _selectedIndex = 0;
        _loadError = null;
        _dataSourceLabel = _fileNameFromPath(filePath);
        _openedSchemaName = initialClassName;
      });
    } catch (e, stackTrace) {
      print('[ERROR] Failed to open realm file: $filePath');
      print('[ERROR] Exception: $e');
      print('[ERROR] Stack: $stackTrace');
      setState(() {
        _loadError = 'Open failed: schema mismatch or unsupported file.\n$e';
      });
    }
  }

  void _selectClass(String className) {
    try {
      final List<Map<String, dynamic>> loaded = _repository.readClassDocuments(
        className,
      );

      setState(() {
        _documents = loaded;
        _pageStart = 0;
        _selectedIndex = 0;
        _query = '';
        _queryController.clear();
        _openedSchemaName = className;
        _loadError = null;
      });
    } catch (e, stackTrace) {
      print('[ERROR] Failed to read class: $className');
      print('[ERROR] Exception: $e');
      print('[ERROR] Stack: $stackTrace');
      setState(() {
        _loadError = 'Read class failed: $className\n$e';
      });
    }
  }

  Future<String?> _showPathInputDialog() async {
    final TextEditingController pathController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Open .realm file'),
          content: TextField(
            controller: pathController,
            decoration: const InputDecoration(
              hintText: '/path/to/your.realm',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(pathController.text),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showEncryptionKeyDialog({String initialValue = ''}) async {
    final TextEditingController keyController = TextEditingController(
      text: initialValue,
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        bool obscure = true;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Realm Encryption Key'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Enter key for encrypted file. Leave empty for non-encrypted realm.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      hintText: 'Base64, 128-hex, or 64-char plain key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            obscure = !obscure;
                          });
                        },
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(keyController.text),
                  child: const Text('Open'),
                ),
              ],
            );
          },
        );
      },
    );

    keyController.dispose();
    return result;
  }

  List<Map<String, dynamic>> get _filteredDocuments {
    final String input = _query.trim().toLowerCase();
    if (input.isEmpty) {
      return _documents;
    }

    return _documents.where((Map<String, dynamic> doc) {
      final String haystack = _safeJsonEncode(doc).toLowerCase();
      return haystack.contains(input);
    }).toList();
  }

  int _normalizedPageStart(int total) {
    if (total <= 0) {
      return 0;
    }

    if (_pageStart < 0) {
      return 0;
    }

    if (_pageStart >= total) {
      return ((total - 1) ~/ _maxDisplayCount) * _maxDisplayCount;
    }

    return (_pageStart ~/ _maxDisplayCount) * _maxDisplayCount;
  }

  List<Map<String, dynamic>> _pagedDocuments(List<Map<String, dynamic>> input) {
    if (input.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final int start = _normalizedPageStart(input.length);
    final int end = (start + _maxDisplayCount).clamp(0, input.length);
    return input.sublist(start, end);
  }

  bool _canPrevPage(int total) {
    return _normalizedPageStart(total) > 0;
  }

  bool _canNextPage(int total) {
    if (total <= 0) {
      return false;
    }
    final int start = _normalizedPageStart(total);
    return start + _maxDisplayCount < total;
  }

  void _goPrevPage(int total) {
    if (!_canPrevPage(total)) {
      return;
    }

    setState(() {
      _pageStart = _normalizedPageStart(total) - _maxDisplayCount;
      _selectedIndex = 0;
    });
  }

  void _goNextPage(int total) {
    if (!_canNextPage(total)) {
      return;
    }

    setState(() {
      _pageStart = _normalizedPageStart(total) + _maxDisplayCount;
      _selectedIndex = 0;
    });
  }

  Map<String, dynamic>? get _selectedDocument {
    final List<Map<String, dynamic>> docs = _pagedDocuments(_filteredDocuments);
    if (docs.isEmpty) {
      return null;
    }

    final int safeIndex = _selectedIndex.clamp(0, docs.length - 1);
    return docs[safeIndex];
  }

  void _runQuery() {
    setState(() {
      _query = _queryController.text;
      _pageStart = 0;
      _selectedIndex = 0;
    });
  }

  void _clearQuery() {
    setState(() {
      _queryController.clear();
      _query = '';
      _pageStart = 0;
      _selectedIndex = 0;
    });
  }

  RealmClassSummary? get _selectedClassSummary {
    final String? schemaName = _openedSchemaName;
    if (schemaName == null) {
      return null;
    }

    for (final RealmClassSummary summary in _classes) {
      if (summary.name == schemaName) {
        return summary;
      }
    }
    return null;
  }

  List<String> get _currentTableColumns {
    final List<String> schemaFields =
        _selectedClassSummary?.fields ?? <String>[];
    if (schemaFields.isEmpty) {
      if (_documents.isEmpty) {
        return const <String>['_id'];
      }
      return _documents.first.keys.toList(growable: false);
    }

    if (schemaFields.contains('_id')) {
      return schemaFields;
    }

    return <String>['_id', ...schemaFields];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Map<String, dynamic>> filteredDocs = _filteredDocuments;
    final int normalizedStart = _normalizedPageStart(filteredDocs.length);
    final List<Map<String, dynamic>> docs = _pagedDocuments(filteredDocs);
    final String displayRangeLabel = docs.isEmpty
        ? 'Display 0 - 0'
        : 'Display $normalizedStart - ${normalizedStart + docs.length}';

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: const Text('Realm Studio'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Open .realm file',
            onPressed: _pickAndOpenRealmFile,
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, SettingPage.routeName);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _QueryPanel(
            controller: _queryController,
            onRunQuery: _runQuery,
            onClearQuery: _clearQuery,
            dataSourceLabel: _dataSourceLabel,
            loadError: _loadError,
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isNarrow = constraints.maxWidth < 900;

                if (isNarrow) {
                  return _MobileBody(
                    classes: _classes,
                    documents: docs,
                    tableColumns: _currentTableColumns,
                    selectedIndex: _selectedIndex,
                    dataSourceLabel: _dataSourceLabel,
                    schemaName: _openedSchemaName,
                    onSelectClass: _selectClass,
                  );
                }

                return Row(
                  children: <Widget>[
                    SizedBox(
                      width: 310,
                      child: _TreeLayerPanel(
                        classes: _classes,
                        documents: docs,
                        selectedIndex: _selectedIndex,
                        dataSourceLabel: _dataSourceLabel,
                        schemaName: _openedSchemaName,
                        onSelectClass: _selectClass,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _DataViewsPanel(
                        documents: docs,
                        tableColumns: _currentTableColumns,
                        displayRangeLabel: displayRangeLabel,
                        canPrev: _canPrevPage(filteredDocs.length),
                        canNext: _canNextPage(filteredDocs.length),
                        onPrev: () => _goPrevPage(filteredDocs.length),
                        onNext: () => _goNextPage(filteredDocs.length),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  Text('Results: ${filteredDocs.length}'),
                  const SizedBox(width: 16),
                  Text(displayRangeLabel),
                  const SizedBox(width: 16),
                  Text('Class: ${_openedSchemaName ?? '-'}'),
                  const SizedBox(width: 16),
                  Text('Selected: ${_selectedDocument?['_id'] ?? '-'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueryPanel extends StatelessWidget {
  const _QueryPanel({
    required this.controller,
    required this.onRunQuery,
    required this.onClearQuery,
    required this.dataSourceLabel,
    required this.loadError,
  });

  final TextEditingController controller;
  final VoidCallback onRunQuery;
  final VoidCallback onClearQuery;
  final String dataSourceLabel;
  final String? loadError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Query Section', style: TextStyle(fontSize: 16)),
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
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Try: active, Bangkok, u001',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => onRunQuery(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onRunQuery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onClearQuery,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileBody extends StatelessWidget {
  const _MobileBody({
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
                _TreeLayerPanel(
                  classes: classes,
                  documents: documents,
                  selectedIndex: selectedIndex,
                  dataSourceLabel: dataSourceLabel,
                  schemaName: schemaName,
                  onSelectClass: onSelectClass,
                ),
                _JsonView(documents: documents),
                _TableView(documents: documents, columns: tableColumns),
                _InspectorView(documents: documents),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeLayerPanel extends StatelessWidget {
  const _TreeLayerPanel({
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
    final Color selectedColor = Theme.of(context).colorScheme.primaryContainer;
    final String selectedClass = schemaName ?? '';

    return ListView(
      physics: const ClampingScrollPhysics(),
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
            title: Text(item.name),
            trailing: _CountBadge(count: item.count),
            onTap: () => onSelectClass(item.name),
          );
        }),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text('$count'),
      ),
    );
  }
}

class _DataViewsPanel extends StatelessWidget {
  const _DataViewsPanel({
    required this.documents,
    required this.tableColumns,
    required this.displayRangeLabel,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final List<Map<String, dynamic>> documents;
  final List<String> tableColumns;
  final String displayRangeLabel;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: <Widget>[
                Text(
                  displayRangeLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: canPrev ? onPrev : null,
                  child: const Text('Prev'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: canNext ? onNext : null,
                  child: const Text('Next'),
                ),
                const SizedBox(width: 12),
                const TabBar(
                  isScrollable: true,
                  tabs: <Tab>[
                    Tab(text: 'JSON'),
                    Tab(text: 'Table'),
                    Tab(text: 'Inspector'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _JsonView(documents: documents),
                _TableView(documents: documents, columns: tableColumns),
                _InspectorView(documents: documents),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView({required this.documents});

  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('No data found for this page'));
    }

    final String pretty = const JsonEncoder.withIndent(
      '  ',
    ).convert(_toJsonSafe(documents));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                pretty,
                style: const TextStyle(height: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({required this.documents, required this.columns});

  final List<Map<String, dynamic>> documents;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('No data found for this query'));
    }

    final List<String> effectiveColumns = columns.isEmpty
        ? documents.first.keys.toList(growable: false)
        : columns;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: effectiveColumns
              .map((String key) => DataColumn(label: Text(key)))
              .toList(growable: false),
          rows: documents
              .map((Map<String, dynamic> doc) {
                return DataRow(
                  cells: effectiveColumns
                      .map((String key) => DataCell(Text('${doc[key] ?? ''}')))
                      .toList(growable: false),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _InspectorView extends StatelessWidget {
  const _InspectorView({required this.documents});

  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('No data found for this page'));
    }

    return Column(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: <Widget>[
                SizedBox(width: 150, child: Text('Key')),
                Expanded(child: Text('Value')),
                SizedBox(width: 90, child: Text('Type')),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: List<Widget>.generate(documents.length, (int index) {
              final Map<String, dynamic> doc = documents[index];
              final String key = doc.containsKey('_id')
                  ? '#$index (${doc['_id']})'
                  : '#$index';
              return _InspectorNodeTile(keyLabel: key, value: doc, depth: 0);
            }),
          ),
        ),
      ],
    );
  }
}

class _InspectorNodeTile extends StatelessWidget {
  const _InspectorNodeTile({
    required this.keyLabel,
    required this.value,
    required this.depth,
  });

  final String keyLabel;
  final dynamic value;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final bool isMap = value is Map<String, dynamic>;
    final bool isList = value is List<dynamic>;
    final bool isComplex = isMap || isList;

    if (!isComplex) {
      return _InspectorRow(
        keyLabel: keyLabel,
        valueLabel: _displayValue(value),
        typeLabel: _valueType(value),
        depth: depth,
      );
    }

    final List<Widget> children = <Widget>[];
    if (isMap) {
      final Map<String, dynamic> map = value as Map<String, dynamic>;
      map.forEach((String key, dynamic childValue) {
        children.add(
          _InspectorNodeTile(
            keyLabel: key,
            value: childValue,
            depth: depth + 1,
          ),
        );
      });
    } else {
      final List<dynamic> list = value as List<dynamic>;
      for (int i = 0; i < list.length; i++) {
        children.add(
          _InspectorNodeTile(
            keyLabel: '[$i]',
            value: list[i],
            depth: depth + 1,
          ),
        );
      }
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 12 + depth * 14, right: 8),
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: false,
      title: Row(
        children: <Widget>[
          SizedBox(width: 150, child: Text(keyLabel)),
          Expanded(child: Text(_displayValue(value))),
          SizedBox(width: 90, child: Text(_valueType(value))),
        ],
      ),
      children: children,
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({
    required this.keyLabel,
    required this.valueLabel,
    required this.typeLabel,
    required this.depth,
  });

  final String keyLabel;
  final String valueLabel;
  final String typeLabel;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12 + depth * 14, 8, 8, 8),
      child: Row(
        children: <Widget>[
          SizedBox(width: 150, child: Text(keyLabel)),
          Expanded(child: Text(valueLabel)),
          SizedBox(width: 90, child: Text(typeLabel)),
        ],
      ),
    );
  }
}

String _valueType(dynamic value) {
  if (value == null) {
    return 'Null';
  }
  if (value is List<dynamic>) {
    return 'Array';
  }
  if (value is Map<String, dynamic>) {
    return 'Object';
  }
  if (value is int) {
    return 'Int';
  }
  if (value is double) {
    return 'Double';
  }
  if (value is bool) {
    return 'Bool';
  }
  return 'String';
}

String _displayValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return '{ ${value.length} fields }';
  }
  if (value is List<dynamic>) {
    return '[ ${value.length} elements ]';
  }
  if (value == null) {
    return 'null';
  }
  return '$value';
}

String _safeJsonEncode(Object? value) {
  return jsonEncode(_toJsonSafe(value));
}

Object? _toJsonSafe(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }

  if (value is DateTime) {
    return value.toIso8601String();
  }

  if (value is Map) {
    final Map<String, dynamic> output = <String, dynamic>{};
    value.forEach((dynamic key, dynamic val) {
      output['$key'] = _toJsonSafe(val);
    });
    return output;
  }

  if (value is Iterable) {
    return value
        .map((Object? item) => _toJsonSafe(item))
        .toList(growable: false);
  }

  return value.toString();
}

String _fileNameFromPath(String path) {
  final int slash = path.lastIndexOf('/');
  if (slash == -1) {
    return path;
  }
  return path.substring(slash + 1);
}
