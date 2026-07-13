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
    } catch (e) {
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
    } catch (e) {
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
      final String haystack = safeJsonEncode(doc).toLowerCase();
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
          HomeQueryPanel(
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
                  return HomeMobileBody(
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
                      child: HomeTreeLayerPanel(
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
                      child: HomeDataViewsPanel(
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

String _fileNameFromPath(String path) {
  final int slash = path.lastIndexOf('/');
  if (slash == -1) {
    return path;
  }
  return path.substring(slash + 1);
}
