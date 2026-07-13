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
  int _selectedIndex = 0;
  String _dataSourceLabel = 'Mock data';
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

    await _openRealmFile(filePath.trim());
  }

  Future<void> _openRealmFile(String filePath) async {
    final File file = File(filePath);
    if (!file.existsSync()) {
      setState(() {
        _loadError = 'File not found: $filePath';
      });
      return;
    }

    try {
      final List<Map<String, dynamic>> loaded = _repository.openAndReadUsers(
        filePath,
      );

      setState(() {
        _documents = loaded;
        _query = '';
        _queryController.clear();
        _selectedIndex = 0;
        _loadError = null;
        _dataSourceLabel = _fileNameFromPath(filePath);
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

  List<Map<String, dynamic>> get _filteredDocuments {
    final String input = _query.trim().toLowerCase();
    if (input.isEmpty) {
      return _documents;
    }

    return _documents.where((Map<String, dynamic> doc) {
      final String haystack = jsonEncode(doc).toLowerCase();
      return haystack.contains(input);
    }).toList();
  }

  Map<String, dynamic>? get _selectedDocument {
    final List<Map<String, dynamic>> docs = _filteredDocuments;
    if (docs.isEmpty) {
      return null;
    }

    final int safeIndex = _selectedIndex.clamp(0, docs.length - 1);
    return docs[safeIndex];
  }

  void _runQuery() {
    setState(() {
      _query = _queryController.text;
      _selectedIndex = 0;
    });
  }

  void _clearQuery() {
    setState(() {
      _queryController.clear();
      _query = '';
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Map<String, dynamic>> docs = _filteredDocuments;

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
                    documents: docs,
                    selectedIndex: _selectedIndex,
                    dataSourceLabel: _dataSourceLabel,
                    onSelectIndex: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                }

                return Row(
                  children: <Widget>[
                    SizedBox(
                      width: 310,
                      child: _TreeLayerPanel(
                        documents: docs,
                        selectedIndex: _selectedIndex,
                        dataSourceLabel: _dataSourceLabel,
                        onSelectIndex: (int index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _DataViewsPanel(
                        selectedDocument: _selectedDocument,
                        documents: docs,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            child: Row(
              children: <Widget>[
                Text('Results: ${docs.length}'),
                const SizedBox(width: 16),
                Text('Selected: ${_selectedDocument?['_id'] ?? '-'}'),
              ],
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
    required this.documents,
    required this.selectedIndex,
    required this.dataSourceLabel,
    required this.onSelectIndex,
  });

  final List<Map<String, dynamic>> documents;
  final int selectedIndex;
  final String dataSourceLabel;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? selected = documents.isEmpty
        ? null
        : documents[selectedIndex.clamp(0, documents.length - 1)];

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
              children: <Widget>[
                _TreeLayerPanel(
                  documents: documents,
                  selectedIndex: selectedIndex,
                  dataSourceLabel: dataSourceLabel,
                  onSelectIndex: onSelectIndex,
                ),
                _JsonView(document: selected),
                _TableView(documents: documents),
                _InspectorView(document: selected),
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
    required this.documents,
    required this.selectedIndex,
    required this.dataSourceLabel,
    required this.onSelectIndex,
  });

  final List<Map<String, dynamic>> documents;
  final int selectedIndex;
  final String dataSourceLabel;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).colorScheme.primaryContainer;

    return ListView(
      children: <Widget>[
        const ListTile(
          dense: true,
          title: Text('Widget Tree Layer'),
          subtitle: Text('realm_gony3t > users collection'),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.link, size: 18),
          title: Text(dataSourceLabel),
        ),
        ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(Icons.storage),
          title: const Text('realm_gony3t'),
          children: <Widget>[
            ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.table_chart),
              title: Text('users (${documents.length})'),
              children: List<Widget>.generate(documents.length, (int index) {
                final Map<String, dynamic> doc = documents[index];
                final bool isSelected = selectedIndex == index;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: selectedColor,
                  leading: const Icon(Icons.description_outlined, size: 18),
                  title: Text('${doc['_id']}'),
                  subtitle: Text(
                    '${doc['name'] ?? ''} • ${doc['status'] ?? ''}',
                  ),
                  onTap: () => onSelectIndex(index),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}

class _DataViewsPanel extends StatelessWidget {
  const _DataViewsPanel({
    required this.selectedDocument,
    required this.documents,
  });

  final Map<String, dynamic>? selectedDocument;
  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          const TabBar(
            tabs: <Tab>[
              Tab(text: 'JSON'),
              Tab(text: 'Table'),
              Tab(text: 'Inspector'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _JsonView(document: selectedDocument),
                _TableView(documents: documents),
                _InspectorView(document: selectedDocument),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView({required this.document});

  final Map<String, dynamic>? document;

  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return const Center(child: Text('No document selected'));
    }

    final String pretty = const JsonEncoder.withIndent('  ').convert(document);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: SelectableText(pretty, style: const TextStyle(height: 1.4)),
        ),
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({required this.documents});

  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('No data found for this query'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text('_id')),
          DataColumn(label: Text('name')),
          DataColumn(label: Text('status')),
          DataColumn(label: Text('age')),
          DataColumn(label: Text('city')),
        ],
        rows: documents.map((Map<String, dynamic> doc) {
          return DataRow(
            cells: <DataCell>[
              DataCell(Text('${doc['_id']}')),
              DataCell(Text('${doc['name'] ?? ''}')),
              DataCell(Text('${doc['status'] ?? ''}')),
              DataCell(Text('${doc['age'] ?? ''}')),
              DataCell(Text('${doc['city'] ?? ''}')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InspectorView extends StatelessWidget {
  const _InspectorView({required this.document});

  final Map<String, dynamic>? document;

  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return const Center(child: Text('No document selected'));
    }

    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: const Row(
            children: <Widget>[
              SizedBox(width: 150, child: Text('Key')),
              Expanded(child: Text('Value')),
              SizedBox(width: 90, child: Text('Type')),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              _InspectorNodeTile(keyLabel: '{ }', value: document, depth: 0),
            ],
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
      initiallyExpanded: depth < 2,
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

String _fileNameFromPath(String path) {
  final int slash = path.lastIndexOf('/');
  if (slash == -1) {
    return path;
  }
  return path.substring(slash + 1);
}
