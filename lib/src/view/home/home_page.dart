import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm_gony3t/realm_gony3t.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const String routeName = '$initRoute/home-page';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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

    final HomeState state = ref.read(homeProvider);
    final String? encryptionKeyInput = await _showEncryptionKeyDialog(
      initialValue: state.lastEncryptionKeyInput,
    );

    if (!mounted || encryptionKeyInput == null) {
      return;
    }

    ref
        .read(homeProvider.notifier)
        .updateLastEncryptionKeyInput(encryptionKeyInput);

    await ref
        .read(homeProvider.notifier)
        .openRealmFile(filePath.trim(), encryptionKeyInput: encryptionKeyInput);
  }

  void _selectClass(String className) {
    ref.read(homeProvider.notifier).selectClass(className);
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
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
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
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

  void _runQuery(int tabId, String input) {
    ref.read(homeProvider.notifier).runQueryForTab(tabId, input);
  }

  void _clearQuery(int tabId) {
    ref.read(homeProvider.notifier).clearQueryForTab(tabId);
  }

  void _activateTabQuery(int tabId, String queryText) {
    final String normalized = queryText.trim();
    ref.read(homeProvider.notifier).activateQueryTab(tabId, normalized);
  }

  Future<String?> _showSaveJsonPathInputDialog({
    required String className,
    required String initialPath,
  }) async {
    final TextEditingController pathController = TextEditingController(
      text: initialPath,
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save JSON for $className'),
          content: TextField(
            controller: pathController,
            decoration: const InputDecoration(
              hintText: '/path/to/export.json',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(pathController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    pathController.dispose();
    return result;
  }

  Future<void> _exportClassFullDepthJson(String className) async {
    String? outputPath;
    try {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save full-depth JSON for $className',
        fileName: '$className-full-depth.json',
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
    } on PlatformException catch (e) {
      if (e.code == 'ENTITLEMENT_REQUIRED_WRITE') {
        final String homePath = Platform.environment['HOME'] ?? '';
        final String fallbackBase = homePath.isEmpty
            ? Directory.systemTemp.path
            : '$homePath/Downloads';
        final String fallbackPath = '$fallbackBase/$className-full-depth.json';

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Save dialog needs macOS write entitlement. Enter a path (default is Downloads).',
              ),
            ),
          );

        outputPath = await _showSaveJsonPathInputDialog(
          className: className,
          initialPath: fallbackPath,
        );
      } else {
        rethrow;
      }
    }

    if (!mounted || outputPath == null || outputPath.trim().isEmpty) {
      return;
    }

    await ref
        .read(homeProvider.notifier)
        .exportClassFullDepthToJson(
          className: className,
          outputPath: outputPath.trim(),
          prettyJson: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HomeState>(homeProvider, (HomeState? previous, HomeState next) {
      if (next.depthSnackbarMessage == null) {
      } else if (previous?.depthSnackbarVersion != next.depthSnackbarVersion) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.depthSnackbarMessage!)));

        ref.read(homeProvider.notifier).clearDepthSnackbarMessage();
      }

      if (next.exportSnackbarMessage == null) {
        return;
      }

      if ((previous?.exportSnackbarVersion ?? 0) ==
          (next.exportSnackbarVersion ?? 0)) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next.exportSnackbarMessage!)));

      ref.read(homeProvider.notifier).clearExportSnackbarMessage();
    });

    final HomeState state = ref.watch(homeProvider);
    final HomeNotifier notifier = ref.read(homeProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final List<Map<String, dynamic>> filteredDocs = state.filteredDocuments;
    final List<Map<String, dynamic>> docs = state.pagedDocuments;

    return Scaffold(
      body: Column(
        children: <Widget>[
          Material(
            elevation: 2,
            color: theme.colorScheme.surface,
            child: HomeQueryPanel(
              onRunQuery: _runQuery,
              onClearQuery: _clearQuery,
              onActivateTabQuery: _activateTabQuery,
              onOpenFile: _pickAndOpenRealmFile,
              onOpenSettings: () {
                Navigator.pushNamed(context, SettingPage.routeName);
              },
              dataSourceLabel: state.dataSourceLabel,
              loadError: state.loadError,
              queryValidationError: state.queryValidationError,
              isQueryRunning:
                  state.isLoadingData && state.query.trim().isNotEmpty,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double viewportWidth = constraints.maxWidth;
                    final bool isNarrow = viewportWidth < 900;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) {
                        return;
                      }
                      ref
                          .read(homeProvider.notifier)
                          .setLayoutWidth(viewportWidth);
                    });

                    if (isNarrow) {
                      return HomeMobileBody(
                        classes: state.classes,
                        documents: docs,
                        tableColumns: state.currentTableColumns,
                        selectedIndex: state.selectedIndex,
                        dataSourceLabel: state.dataSourceLabel,
                        schemaName: state.openedSchemaName,
                        onSelectClass: _selectClass,
                        onExportClassFullDepthJson: _exportClassFullDepthJson,
                      );
                    }

                    return Row(
                      children: <Widget>[
                        SizedBox(
                          width: state.leftPanelWidth.clamp(
                            HomeNotifier.minLeftPanelWidth,
                            (viewportWidth * 0.6).clamp(
                              HomeNotifier.minLeftPanelWidth,
                              HomeNotifier.maxLeftPanelWidth,
                            ),
                          ),
                          child: HomeTreeLayerPanel(
                            classes: state.classes,
                            documents: docs,
                            selectedIndex: state.selectedIndex,
                            dataSourceLabel: state.dataSourceLabel,
                            schemaName: state.openedSchemaName,
                            onSelectClass: _selectClass,
                            onExportClassFullDepthJson:
                                _exportClassFullDepthJson,
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate:
                                (DragUpdateDetails details) {
                                  notifier.adjustLeftPanelWidth(
                                    delta: details.delta.dx,
                                    viewportWidth: viewportWidth,
                                  );
                                },
                            child: const SizedBox(
                              width: 10,
                              child: Center(child: VerticalDivider(width: 1)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: HomeDataViewsPanel(
                            documents: docs,
                            tableColumns: state.currentTableColumns,
                            displayRangeLabel: state.displayRangeLabel,
                            currentDepth: state.loadDepth,
                            isLoading: state.isLoadingData,
                            depthOptions: const <int>[
                              3,
                              5,
                              7,
                              10,
                              HomeNotifier.fullLoadDepth,
                            ],
                            onSelectDepth:
                                notifier.setDepthAndReloadCurrentPage,
                            canPrev: state.canPrevPage,
                            canNext: state.canNextPage,
                            onPrev: notifier.goPrevPage,
                            onNext: notifier.goNextPage,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text('Results: ${filteredDocs.length}'),
                      const SizedBox(width: 16),
                      Text(state.displayRangeLabel),
                      const SizedBox(width: 16),
                      Text('Class: ${state.openedSchemaName ?? '-'}'),
                    ],
                  ),
                ),
                if (state.isExportingClassJson ?? false) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            state.exportClassJsonStatus ??
                                'Exporting full-depth JSON...',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${((state.exportClassJsonProgress ?? 0) * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: (state.exportClassJsonProgress ?? 0).clamp(0, 1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
