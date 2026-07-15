import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm_gony3t/realm_gony3t.dart';

final NotifierProvider<HomeNotifier, HomeState> homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

class HomeState {
  const HomeState({
    required this.documents,
    required this.query,
    required this.classSearchQuery,
    required this.loadDepth,
    required this.pageStart,
    required this.selectedIndex,
    required this.dataSourceLabel,
    required this.classes,
    required this.viewportWidth,
    required this.leftPanelWidth,
    required this.lastEncryptionKeyInput,
    required this.isLoadingData,
    required this.queryValidationError,
    required this.depthSnackbarVersion,
    this.isExportingClassJson,
    this.exportClassJsonProgress,
    this.exportSnackbarVersion,
    this.openedSchemaName,
    this.loadError,
    this.depthSnackbarMessage,
    this.exportClassJsonStatus,
    this.exportSnackbarMessage,
  });

  factory HomeState.initial() {
    return const HomeState(
      documents: <Map<String, dynamic>>[
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
      ],
      query: '',
      classSearchQuery: '',
      loadDepth: 3,
      pageStart: 0,
      selectedIndex: 0,
      dataSourceLabel: 'Mock data',
      classes: <RealmClassSummary>[],
      viewportWidth: 0,
      leftPanelWidth: 310,
      lastEncryptionKeyInput: '',
      isLoadingData: false,
      queryValidationError: null,
      depthSnackbarVersion: 0,
      isExportingClassJson: false,
      exportClassJsonProgress: 0,
      exportSnackbarVersion: 0,
      openedSchemaName: null,
      loadError: null,
      depthSnackbarMessage: null,
      exportClassJsonStatus: null,
      exportSnackbarMessage: null,
    );
  }

  static const int pageSize = 50;

  final List<Map<String, dynamic>> documents;
  final String query;
  final String classSearchQuery;
  final int loadDepth;
  final int pageStart;
  final int selectedIndex;
  final String dataSourceLabel;
  final List<RealmClassSummary> classes;
  final String? openedSchemaName;
  final String? loadError;
  final double viewportWidth;
  final double leftPanelWidth;
  final String lastEncryptionKeyInput;
  final bool isLoadingData;
  final String? queryValidationError;
  final String? depthSnackbarMessage;
  final int depthSnackbarVersion;
  final bool? isExportingClassJson;
  final double? exportClassJsonProgress;
  final String? exportClassJsonStatus;
  final String? exportSnackbarMessage;
  final int? exportSnackbarVersion;

  HomeState copyWith({
    List<Map<String, dynamic>>? documents,
    String? query,
    String? classSearchQuery,
    int? loadDepth,
    int? pageStart,
    int? selectedIndex,
    String? dataSourceLabel,
    List<RealmClassSummary>? classes,
    String? openedSchemaName,
    Object? loadError = _noChange,
    double? viewportWidth,
    double? leftPanelWidth,
    String? lastEncryptionKeyInput,
    bool? isLoadingData,
    Object? queryValidationError = _noChange,
    Object? depthSnackbarMessage = _noChange,
    int? depthSnackbarVersion,
    bool? isExportingClassJson,
    double? exportClassJsonProgress,
    Object? exportClassJsonStatus = _noChange,
    Object? exportSnackbarMessage = _noChange,
    int? exportSnackbarVersion,
  }) {
    return HomeState(
      documents: documents ?? this.documents,
      query: query ?? this.query,
      classSearchQuery: classSearchQuery ?? this.classSearchQuery,
      loadDepth: loadDepth ?? this.loadDepth,
      pageStart: pageStart ?? this.pageStart,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      dataSourceLabel: dataSourceLabel ?? this.dataSourceLabel,
      classes: classes ?? this.classes,
      openedSchemaName: openedSchemaName ?? this.openedSchemaName,
      loadError: identical(loadError, _noChange)
          ? this.loadError
          : loadError as String?,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      leftPanelWidth: leftPanelWidth ?? this.leftPanelWidth,
      lastEncryptionKeyInput:
          lastEncryptionKeyInput ?? this.lastEncryptionKeyInput,
      isLoadingData: isLoadingData ?? this.isLoadingData,
      queryValidationError: identical(queryValidationError, _noChange)
          ? this.queryValidationError
          : queryValidationError as String?,
      depthSnackbarMessage: identical(depthSnackbarMessage, _noChange)
          ? this.depthSnackbarMessage
          : depthSnackbarMessage as String?,
      depthSnackbarVersion: depthSnackbarVersion ?? this.depthSnackbarVersion,
      isExportingClassJson: isExportingClassJson ?? this.isExportingClassJson,
      exportClassJsonProgress:
          exportClassJsonProgress ?? this.exportClassJsonProgress,
      exportClassJsonStatus: identical(exportClassJsonStatus, _noChange)
          ? this.exportClassJsonStatus
          : exportClassJsonStatus as String?,
      exportSnackbarMessage: identical(exportSnackbarMessage, _noChange)
          ? this.exportSnackbarMessage
          : exportSnackbarMessage as String?,
      exportSnackbarVersion:
          exportSnackbarVersion ?? this.exportSnackbarVersion,
    );
  }

  bool get isNarrow => viewportWidth < 900;

  RealmClassSummary? get selectedClassSummary {
    final String? schemaName = openedSchemaName;
    if (schemaName == null) {
      return null;
    }

    for (final RealmClassSummary summary in classes) {
      if (summary.name == schemaName) {
        return summary;
      }
    }

    return null;
  }

  List<String> get currentTableColumns {
    final List<String> schemaFields =
        selectedClassSummary?.fields ?? <String>[];
    if (schemaFields.isEmpty) {
      if (documents.isEmpty) {
        return const <String>[];
      }
      return documents.first.keys
          .where((String key) => key != '_id')
          .toList(growable: false);
    }

    return schemaFields
        .where((String key) => key != '_id')
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get filteredDocuments {
    final String input = query.trim();
    if (input.isEmpty) {
      return documents;
    }

    return documents
        .where((Map<String, dynamic> doc) {
          return _matchesQueryExpression(doc, input);
        })
        .toList(growable: false);
  }

  int get normalizedPageStart {
    final bool isQueryMode = query.trim().isNotEmpty;
    final int total = isQueryMode
        ? filteredDocuments.length
        : (selectedClassSummary?.count ?? documents.length);
    if (total <= 0) {
      return 0;
    }

    if (pageStart < 0) {
      return 0;
    }

    if (pageStart >= total) {
      return ((total - 1) ~/ pageSize) * pageSize;
    }

    return (pageStart ~/ pageSize) * pageSize;
  }

  List<Map<String, dynamic>> get pagedDocuments {
    if (query.trim().isEmpty) {
      return documents;
    }

    final List<Map<String, dynamic>> filtered = filteredDocuments;
    if (filtered.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final int start = normalizedPageStart.clamp(0, filtered.length);
    final int end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  bool get canPrevPage => normalizedPageStart > 0;

  bool get canNextPage {
    final bool isQueryMode = query.trim().isNotEmpty;
    final int total = isQueryMode
        ? filteredDocuments.length
        : (selectedClassSummary?.count ?? documents.length);
    if (total <= 0) {
      return false;
    }
    return normalizedPageStart + pageSize < total;
  }

  Map<String, dynamic>? get selectedDocument {
    final List<Map<String, dynamic>> docs = pagedDocuments;
    if (docs.isEmpty) {
      return null;
    }

    final int safeIndex = selectedIndex.clamp(0, docs.length - 1);
    return docs[safeIndex];
  }

  String get displayRangeLabel {
    if (query.trim().isNotEmpty) {
      final int total = filteredDocuments.length;
      if (total <= 0) {
        return 'Query results: 0';
      }
      final int start = normalizedPageStart + 1;
      final int end = normalizedPageStart + pagedDocuments.length;
      return 'Query $start - $end of $total';
    }

    final List<Map<String, dynamic>> docs = documents;
    if (docs.isEmpty) {
      return 'Display 0 - 0';
    }
    return 'Display $normalizedPageStart - ${normalizedPageStart + docs.length}';
  }
}

class HomeNotifier extends Notifier<HomeState> {
  final RealmUserRepository _repository = RealmUserRepository();
  static const double minLeftPanelWidth = 220;
  static const double maxLeftPanelWidth = 520;
  static const int fullLoadDepth = -1;
  static const int minLoadDepth = 1;
  static const int defaultLoadDepth = 3;
  static const int maxLoadDepth = 20;
  static const int _largeClassThreshold = 200;
  static const int _veryLargeClassThreshold = 500;
  static const int _safeDepthForLargeClass = 7;
  static const int _safeDepthForVeryLargeClass = 5;
  int _activeLoadToken = 0;

  @override
  HomeState build() {
    ref.onDispose(_repository.close);
    return HomeState.initial();
  }

  bool setLayoutWidth(double width) {
    if (state.viewportWidth != width) {
      state = state.copyWith(viewportWidth: width);
    }
    return width < 900;
  }

  void adjustLeftPanelWidth({
    required double delta,
    required double viewportWidth,
  }) {
    final double maxAllowed = (viewportWidth * 0.6).clamp(
      minLeftPanelWidth,
      maxLeftPanelWidth,
    );
    final double nextWidth = (state.leftPanelWidth + delta).clamp(
      minLeftPanelWidth,
      maxAllowed,
    );
    if (nextWidth == state.leftPanelWidth) {
      return;
    }
    state = state.copyWith(leftPanelWidth: nextWidth);
  }

  void updateLastEncryptionKeyInput(String input) {
    if (state.lastEncryptionKeyInput == input) {
      return;
    }
    state = state.copyWith(lastEncryptionKeyInput: input);
  }

  void updateClassSearchQuery(String input) {
    if (state.classSearchQuery == input) {
      return;
    }
    state = state.copyWith(classSearchQuery: input);
  }

  Future<void> openRealmFile(
    String filePath, {
    String? encryptionKeyInput,
  }) async {
    final File file = File(filePath);
    if (!file.existsSync()) {
      state = state.copyWith(loadError: 'File not found: $filePath');
      return;
    }

    try {
      state = state.copyWith(isLoadingData: true, loadError: null);

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

      state = state.copyWith(
        classes: classes,
        documents: const <Map<String, dynamic>>[],
        query: '',
        queryValidationError: null,
        classSearchQuery: '',
        loadDepth: defaultLoadDepth,
        pageStart: 0,
        selectedIndex: 0,
        loadError: null,
        dataSourceLabel: _fileNameFromPath(filePath),
        openedSchemaName: initialClassName,
      );

      if (initialClassName != null) {
        final int token = ++_activeLoadToken;
        await _loadClassPage(initialClassName, pageStart: 0, token: token);
      } else {
        state = state.copyWith(isLoadingData: false);
      }
    } catch (e) {
      state = state.copyWith(
        loadError: 'Open failed: schema mismatch or unsupported file.\n$e',
        isLoadingData: false,
      );
    }
  }

  Future<void> selectClass(String className) async {
    try {
      state = state.copyWith(
        documents: const <Map<String, dynamic>>[],
        pageStart: 0,
        selectedIndex: 0,
        query: '',
        queryValidationError: null,
        classSearchQuery: state.classSearchQuery,
        loadDepth: defaultLoadDepth,
        openedSchemaName: className,
        loadError: null,
        isLoadingData: true,
      );

      final int token = ++_activeLoadToken;
      await _loadClassPage(className, pageStart: 0, token: token);
    } catch (e) {
      state = state.copyWith(
        loadError: 'Read class failed: $className\n$e',
        isLoadingData: false,
      );
    }
  }

  Future<void> _loadClassPage(
    String className, {
    required int pageStart,
    required int token,
  }) async {
    if (token != _activeLoadToken) {
      return;
    }

    state = state.copyWith(isLoadingData: true);
    await Future<void>.delayed(Duration.zero);

    final Stopwatch watch = Stopwatch()..start();
    try {
      final int batchSize = _batchSizeForDepth(state.loadDepth);
      final List<Map<String, dynamic>> loaded = <Map<String, dynamic>>[];
      int offset = pageStart;

      while (loaded.length < HomeState.pageSize) {
        final int remaining = HomeState.pageSize - loaded.length;
        final int limit = remaining < batchSize ? remaining : batchSize;

        final List<Map<String, dynamic>> chunk = await _repository
            .readClassDocumentsAsync(
              className,
              offset: offset,
              limit: limit,
              maxDepth: state.loadDepth == fullLoadDepth
                  ? null
                  : state.loadDepth,
              yieldEvery: _yieldEveryForDepth(state.loadDepth),
            );

        if (token != _activeLoadToken) {
          return;
        }

        if (chunk.isEmpty) {
          break;
        }

        loaded.addAll(chunk);
        offset += chunk.length;

        if (chunk.length < limit) {
          break;
        }

        await Future<void>.delayed(Duration.zero);
      }
      watch.stop();

      if (token != _activeLoadToken) {
        return;
      }

      state = state.copyWith(
        documents: List<Map<String, dynamic>>.unmodifiable(loaded),
        pageStart: pageStart,
        selectedIndex: 0,
        query: '',
        queryValidationError: null,
        openedSchemaName: className,
        loadError: null,
        isLoadingData: false,
      );

      debugPrint(
        '[HomeNotifier] class=$className pageStart=$pageStart loaded=${loaded.length} '
        'depth=${state.loadDepth == fullLoadDepth ? 'full' : state.loadDepth} '
        'batchSize=$batchSize '
        'expected=${_classCountByName(className)} '
        'elapsed=${watch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      if (token != _activeLoadToken) {
        return;
      }
      state = state.copyWith(
        loadError: 'Load page failed: $className\n$e',
        isLoadingData: false,
      );
    }
  }

  void setDepthAndReloadCurrentPage(int depth) {
    final String? className = state.openedSchemaName;
    if (className == null) {
      return;
    }

    final int requestedDepth = depth == fullLoadDepth
        ? fullLoadDepth
        : depth.clamp(minLoadDepth, maxLoadDepth);
    final int effectiveDepth = _resolveSafeDepthForClass(
      className: className,
      requestedDepth: requestedDepth,
    );

    if (state.loadDepth == effectiveDepth) {
      return;
    }

    state = state.copyWith(
      loadDepth: effectiveDepth,
      loadError: requestedDepth == effectiveDepth
          ? null
          : 'Depth $requestedDepth is heavy for this class. '
                'Using depth $effectiveDepth to prevent freeze.',
      depthSnackbarMessage:
          requestedDepth == fullLoadDepth && effectiveDepth != fullLoadDepth
          ? 'Full depth for $className is limited to depth $effectiveDepth for performance.'
          : null,
      depthSnackbarVersion:
          requestedDepth == fullLoadDepth && effectiveDepth != fullLoadDepth
          ? state.depthSnackbarVersion + 1
          : state.depthSnackbarVersion,
    );
    final int token = ++_activeLoadToken;
    _loadClassPage(
      className,
      pageStart: state.normalizedPageStart,
      token: token,
    );
  }

  void clearDepthSnackbarMessage() {
    if (state.depthSnackbarMessage == null) {
      return;
    }
    state = state.copyWith(depthSnackbarMessage: null);
  }

  Future<void> exportClassFullDepthToJson({
    required String className,
    required String outputPath,
    bool prettyJson = false,
  }) async {
    if (state.isExportingClassJson ?? false) {
      return;
    }

    final int total = _classCountByName(className);
    state = state.copyWith(
      isExportingClassJson: true,
      exportClassJsonProgress: 0,
      exportClassJsonStatus: 'Exporting $className (full depth)...',
      exportSnackbarMessage: null,
      loadError: null,
    );

    RandomAccessFile? raf;
    try {
      final File outFile = File(outputPath);
      if (!outFile.parent.existsSync()) {
        outFile.parent.createSync(recursive: true);
      }

      raf = await outFile.open(mode: FileMode.write);
      await raf.writeString('[');

      const int chunkSize = 5;
      int offset = 0;
      int written = 0;
      bool first = true;

      while (true) {
        final List<Map<String, dynamic>> chunk = await _repository
            .readClassDocumentsAsync(
              className,
              offset: offset,
              limit: chunkSize,
              maxDepth: null,
              yieldEvery: 1,
            );

        if (chunk.isEmpty) {
          break;
        }

        for (final Map<String, dynamic> row in chunk) {
          if (prettyJson) {
            if (first) {
              await raf.writeString('\n');
            } else {
              await raf.writeString(',\n');
            }
            await raf.writeString(_indentMultiline(_safePrettyJsonEncode(row)));
          } else {
            if (!first) {
              await raf.writeString(',');
            }
            await raf.writeString(_safeJsonEncode(row));
          }
          first = false;
        }

        written += chunk.length;
        offset += chunk.length;

        final double progress = total > 0
            ? (written / total).clamp(0, 1).toDouble()
            : 0;
        state = state.copyWith(
          isExportingClassJson: true,
          exportClassJsonProgress: progress,
          exportClassJsonStatus: total > 0
              ? 'Exporting $className (full depth): $written/$total'
              : 'Exporting $className (full depth): $written',
        );

        if (chunk.length < chunkSize) {
          break;
        }

        await Future<void>.delayed(Duration.zero);
      }

      if (prettyJson && !first) {
        await raf.writeString('\n');
      }
      await raf.writeString(']');
      await raf.flush();
      await raf.close();
      raf = null;

      state = state.copyWith(
        isExportingClassJson: false,
        exportClassJsonProgress: 1,
        exportClassJsonStatus: 'Export complete: $className',
        exportSnackbarMessage: prettyJson
            ? 'Saved pretty full-depth JSON for $className'
            : 'Saved full-depth JSON for $className',
        exportSnackbarVersion: (state.exportSnackbarVersion ?? 0) + 1,
      );
    } on FileSystemException catch (e) {
      try {
        await raf?.close();
      } catch (_) {}
      state = state.copyWith(
        isExportingClassJson: false,
        exportClassJsonProgress: 0,
        exportClassJsonStatus: null,
        loadError: 'Export failed: $className\n$e',
        exportSnackbarMessage:
            'Export failed: no write permission for selected path.',
        exportSnackbarVersion: (state.exportSnackbarVersion ?? 0) + 1,
      );
    } catch (e) {
      try {
        await raf?.close();
      } catch (_) {}
      state = state.copyWith(
        isExportingClassJson: false,
        exportClassJsonProgress: 0,
        exportClassJsonStatus: null,
        loadError: 'Export failed: $className\n$e',
        exportSnackbarMessage: 'Export failed for $className',
        exportSnackbarVersion: (state.exportSnackbarVersion ?? 0) + 1,
      );
    }
  }

  void clearExportSnackbarMessage() {
    if (state.exportSnackbarMessage == null) {
      return;
    }
    state = state.copyWith(exportSnackbarMessage: null);
  }

  int _classCountByName(String className) {
    for (final RealmClassSummary summary in state.classes) {
      if (summary.name == className) {
        return summary.count;
      }
    }
    return -1;
  }

  void runQuery(String query) {
    final String normalized = query.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(
        query: '',
        queryValidationError: null,
        pageStart: 0,
        selectedIndex: 0,
      );
      return;
    }

    final String? validationError = _validateQuerySyntax(normalized);
    if (validationError != null) {
      state = state.copyWith(
        queryValidationError: validationError,
        pageStart: 0,
        selectedIndex: 0,
      );
      return;
    }

    _runQueryAcrossAllDocuments(normalized);
  }

  void _runQueryAcrossAllDocuments(String normalized) {
    final String? className = state.openedSchemaName;
    if (className == null) {
      state = state.copyWith(
        query: normalized,
        queryValidationError: null,
        pageStart: 0,
        selectedIndex: 0,
      );
      return;
    }

    final int token = ++_activeLoadToken;
    state = state.copyWith(
      query: normalized,
      queryValidationError: null,
      pageStart: 0,
      selectedIndex: 0,
      isLoadingData: true,
    );

    Future<void>(() async {
      final Stopwatch watch = Stopwatch()..start();

      try {
        final List<Map<String, dynamic>> loaded = await _repository
            .readClassDocumentsAsync(
              className,
              offset: 0,
              limit: null,
              maxDepth: state.loadDepth == fullLoadDepth
                  ? null
                  : state.loadDepth,
              yieldEvery: _yieldEveryForDepth(state.loadDepth),
            );
        watch.stop();

        if (token != _activeLoadToken) {
          return;
        }

        state = state.copyWith(
          documents: List<Map<String, dynamic>>.unmodifiable(loaded),
          pageStart: 0,
          selectedIndex: 0,
          openedSchemaName: className,
          loadError: null,
          isLoadingData: false,
        );

        debugPrint(
          '[HomeNotifier][query] class=$className loadedAll=${loaded.length} '
          'query="$normalized" elapsed=${watch.elapsedMilliseconds}ms',
        );
      } catch (e) {
        if (token != _activeLoadToken) {
          return;
        }

        state = state.copyWith(
          loadError: 'Query failed: $className\n$e',
          isLoadingData: false,
        );
      }
    });
  }

  void clearQuery() {
    state = state.copyWith(
      query: '',
      queryValidationError: null,
      pageStart: 0,
      selectedIndex: 0,
    );
  }

  void goPrevPage() {
    if (!state.canPrevPage) {
      return;
    }

    if (state.query.trim().isNotEmpty) {
      final int targetStart = state.normalizedPageStart - HomeState.pageSize;
      _goQueryPageWithLoading(targetStart);
      return;
    }

    final String? className = state.openedSchemaName;
    if (className == null) {
      return;
    }

    final int targetStart = state.normalizedPageStart - HomeState.pageSize;
    final int token = ++_activeLoadToken;
    _loadClassPage(className, pageStart: targetStart, token: token);
  }

  void goNextPage() {
    if (!state.canNextPage) {
      return;
    }

    if (state.query.trim().isNotEmpty) {
      final int targetStart = state.normalizedPageStart + HomeState.pageSize;
      _goQueryPageWithLoading(targetStart);
      return;
    }

    final String? className = state.openedSchemaName;
    if (className == null) {
      return;
    }

    final int targetStart = state.normalizedPageStart + HomeState.pageSize;
    final int token = ++_activeLoadToken;
    _loadClassPage(className, pageStart: targetStart, token: token);
  }

  void _goQueryPageWithLoading(int targetStart) {
    final int token = ++_activeLoadToken;
    state = state.copyWith(isLoadingData: true);

    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (token != _activeLoadToken) {
        return;
      }

      state = state.copyWith(
        pageStart: targetStart,
        selectedIndex: 0,
        isLoadingData: false,
      );
    });
  }

  int _resolveSafeDepthForClass({
    required String className,
    required int requestedDepth,
  }) {
    final int count = _classCountByName(className);
    if (count <= 0) {
      return requestedDepth;
    }

    if (count >= _veryLargeClassThreshold) {
      if (requestedDepth == fullLoadDepth ||
          requestedDepth > _safeDepthForVeryLargeClass) {
        return _safeDepthForVeryLargeClass;
      }
      return requestedDepth;
    }

    if (count >= _largeClassThreshold) {
      if (requestedDepth == fullLoadDepth ||
          requestedDepth > _safeDepthForLargeClass) {
        return _safeDepthForLargeClass;
      }
      return requestedDepth;
    }

    return requestedDepth;
  }

  int _yieldEveryForDepth(int depth) {
    if (depth == fullLoadDepth || depth >= 7) {
      return 1;
    }
    if (depth >= 5) {
      return 1;
    }
    return 4;
  }

  int _batchSizeForDepth(int depth) {
    if (depth == fullLoadDepth || depth >= 10) {
      return 3;
    }
    if (depth >= 7) {
      return 5;
    }
    if (depth >= 5) {
      return 8;
    }
    return HomeState.pageSize;
  }
}

const Object _noChange = Object();

String _fileNameFromPath(String path) {
  final int slash = path.lastIndexOf('/');
  if (slash == -1) {
    return path;
  }
  return path.substring(slash + 1);
}

String _safeJsonEncode(Object? value) {
  return jsonEncode(_toJsonSafe(value));
}

String _safePrettyJsonEncode(Object? value) {
  return const JsonEncoder.withIndent('  ').convert(_toJsonSafe(value));
}

String _indentMultiline(String input, [String indent = '  ']) {
  final List<String> lines = input.split('\n');
  return lines.map((String line) => '$indent$line').join('\n');
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

bool _matchesQueryExpression(Map<String, dynamic> doc, String input) {
  try {
    final List<_QueryToken> tokens = _tokenizeQuery(input);
    final _QueryParser parser = _QueryParser(
      tokens: tokens,
      evaluateClause: (String clause) => _matchesClause(doc, clause),
    );
    return parser.parse();
  } on _QuerySyntaxException {
    return false;
  }
}

String? _validateQuerySyntax(String input) {
  try {
    final List<_QueryToken> tokens = _tokenizeQuery(input);
    final _QueryParser parser = _QueryParser(
      tokens: tokens,
      evaluateClause: (String _) => true,
    );
    parser.parse();
    return null;
  } on _QuerySyntaxException catch (e) {
    return e.message;
  }
}

bool _matchesClause(Map<String, dynamic> doc, String clause) {
  final Match? match = RegExp(
    r'^([A-Za-z0-9_.$\[\]-]+)\s*(==|=|!=|>=|<=|>|<|:)\s*(.+)$',
  ).firstMatch(clause);

  if (match == null) {
    final String haystack = _safeJsonEncode(doc).toLowerCase();
    return haystack.contains(clause.toLowerCase());
  }

  final String path = match.group(1)!.trim();
  final String op = match.group(2)!.trim();
  final String rawExpected = _stripQueryQuotes(match.group(3)!.trim());
  final dynamic actual = _readQueryPath(doc, path);

  return _matchesQueryOperator(actual, op, rawExpected);
}

dynamic _readQueryPath(Map<String, dynamic> doc, String path) {
  final List<String> parts = path.split('.');
  dynamic current = doc;

  for (final String part in parts) {
    if (current is Map<String, dynamic>) {
      current = current[part];
      continue;
    }

    return null;
  }

  return current;
}

bool _matchesQueryOperator(dynamic actual, String op, String rawExpected) {
  final String expectedLower = rawExpected.toLowerCase();
  final String actualText = (actual ?? 'null').toString();
  final String actualLower = actualText.toLowerCase();

  switch (op) {
    case ':':
      return actualLower.contains(expectedLower);
    case '=':
    case '==':
      return actualLower == expectedLower;
    case '!=':
      return actualLower != expectedLower;
    case '>':
    case '>=':
    case '<':
    case '<=':
      final num? left = _toNum(actual);
      final num? right = num.tryParse(rawExpected);
      if (left == null || right == null) {
        return false;
      }
      if (op == '>') {
        return left > right;
      }
      if (op == '>=') {
        return left >= right;
      }
      if (op == '<') {
        return left < right;
      }
      return left <= right;
    default:
      return false;
  }
}

num? _toNum(dynamic value) {
  if (value is num) {
    return value;
  }
  if (value == null) {
    return null;
  }
  return num.tryParse(value.toString());
}

String _stripQueryQuotes(String input) {
  if (input.length >= 2 &&
      ((input.startsWith('"') && input.endsWith('"')) ||
          (input.startsWith("'") && input.endsWith("'")))) {
    return input.substring(1, input.length - 1);
  }
  return input;
}

class _QuerySyntaxException implements Exception {
  const _QuerySyntaxException(this.message);

  final String message;
}

enum _QueryTokenType { lParen, rParen, and, or, clause }

class _QueryToken {
  const _QueryToken(this.type, this.text);

  final _QueryTokenType type;
  final String text;
}

List<_QueryToken> _tokenizeQuery(String input) {
  final List<_QueryToken> tokens = <_QueryToken>[];
  final StringBuffer buffer = StringBuffer();
  bool inQuote = false;
  String quoteChar = '';

  void flushClause() {
    final String clause = buffer.toString().trim();
    buffer.clear();
    if (clause.isNotEmpty) {
      tokens.add(_QueryToken(_QueryTokenType.clause, clause));
    }
  }

  for (int i = 0; i < input.length; i++) {
    final String ch = input[i];

    if (inQuote) {
      buffer.write(ch);
      if (ch == quoteChar) {
        inQuote = false;
      }
      continue;
    }

    if (ch == '"' || ch == "'") {
      inQuote = true;
      quoteChar = ch;
      buffer.write(ch);
      continue;
    }

    if (ch == '(') {
      flushClause();
      tokens.add(const _QueryToken(_QueryTokenType.lParen, '('));
      continue;
    }

    if (ch == ')') {
      flushClause();
      tokens.add(const _QueryToken(_QueryTokenType.rParen, ')'));
      continue;
    }

    if (ch == '&' && i + 1 < input.length && input[i + 1] == '&') {
      flushClause();
      tokens.add(const _QueryToken(_QueryTokenType.and, '&&'));
      i++;
      continue;
    }

    if (ch == '|' && i + 1 < input.length && input[i + 1] == '|') {
      flushClause();
      tokens.add(const _QueryToken(_QueryTokenType.or, '||'));
      i++;
      continue;
    }

    buffer.write(ch);
  }

  if (inQuote) {
    throw const _QuerySyntaxException(
      'Query syntax error: missing closing quote',
    );
  }

  flushClause();

  if (tokens.isEmpty) {
    throw const _QuerySyntaxException('Query syntax error: empty expression');
  }

  return tokens;
}

class _QueryParser {
  _QueryParser({required this.tokens, required this.evaluateClause});

  final List<_QueryToken> tokens;
  final bool Function(String clause) evaluateClause;
  int _index = 0;

  bool parse() {
    final bool result = _parseOrExpression();
    if (_index != tokens.length) {
      throw const _QuerySyntaxException(
        'Query syntax error: unexpected token at end of expression',
      );
    }
    return result;
  }

  bool _parseOrExpression() {
    bool left = _parseAndExpression();
    while (_match(_QueryTokenType.or)) {
      left = left || _parseAndExpression();
    }
    return left;
  }

  bool _parseAndExpression() {
    bool left = _parsePrimary();
    while (_match(_QueryTokenType.and)) {
      left = left && _parsePrimary();
    }
    return left;
  }

  bool _parsePrimary() {
    if (_match(_QueryTokenType.lParen)) {
      final bool inner = _parseOrExpression();
      if (!_match(_QueryTokenType.rParen)) {
        throw const _QuerySyntaxException(
          'Query syntax error: missing closing parenthesis',
        );
      }
      return inner;
    }

    final _QueryToken? token = _consume(_QueryTokenType.clause);
    if (token == null) {
      throw const _QuerySyntaxException(
        'Query syntax error: expected condition',
      );
    }
    return evaluateClause(token.text);
  }

  bool _match(_QueryTokenType type) {
    final _QueryToken? token = _peek();
    if (token == null || token.type != type) {
      return false;
    }
    _index++;
    return true;
  }

  _QueryToken? _consume(_QueryTokenType type) {
    final _QueryToken? token = _peek();
    if (token == null || token.type != type) {
      return null;
    }
    _index++;
    return token;
  }

  _QueryToken? _peek() {
    if (_index >= tokens.length) {
      return null;
    }
    return tokens[_index];
  }
}
