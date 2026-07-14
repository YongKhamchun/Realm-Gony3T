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
    this.openedSchemaName,
    this.loadError,
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
      openedSchemaName: null,
      loadError: null,
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
    final String input = query.trim().toLowerCase();
    if (input.isEmpty) {
      return documents;
    }

    return documents
        .where((Map<String, dynamic> doc) {
          final String haystack = _safeJsonEncode(doc).toLowerCase();
          return haystack.contains(input);
        })
        .toList(growable: false);
  }

  int get normalizedPageStart {
    final int total = selectedClassSummary?.count ?? documents.length;
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
    return filteredDocuments;
  }

  bool get canPrevPage => normalizedPageStart > 0;

  bool get canNextPage {
    final int total = selectedClassSummary?.count ?? documents.length;
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
      final List<Map<String, dynamic>> loaded = _repository.readClassDocuments(
        className,
        offset: pageStart,
        limit: HomeState.pageSize,
        maxDepth: state.loadDepth == fullLoadDepth ? null : state.loadDepth,
      );
      watch.stop();

      if (token != _activeLoadToken) {
        return;
      }

      state = state.copyWith(
        documents: List<Map<String, dynamic>>.unmodifiable(loaded),
        pageStart: pageStart,
        selectedIndex: 0,
        query: '',
        openedSchemaName: className,
        loadError: null,
        isLoadingData: false,
      );

      debugPrint(
        '[HomeNotifier] class=$className pageStart=$pageStart loaded=${loaded.length} '
        'depth=${state.loadDepth == fullLoadDepth ? 'full' : state.loadDepth} '
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

    final int normalizedDepth = depth == fullLoadDepth
        ? fullLoadDepth
        : depth.clamp(minLoadDepth, maxLoadDepth);
    if (state.loadDepth == normalizedDepth) {
      return;
    }

    state = state.copyWith(loadDepth: normalizedDepth);
    final int token = ++_activeLoadToken;
    _loadClassPage(
      className,
      pageStart: state.normalizedPageStart,
      token: token,
    );
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
    state = state.copyWith(query: query, pageStart: 0, selectedIndex: 0);
  }

  void clearQuery() {
    state = state.copyWith(query: '', pageStart: 0, selectedIndex: 0);
  }

  void goPrevPage() {
    if (!state.canPrevPage) {
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

    final String? className = state.openedSchemaName;
    if (className == null) {
      return;
    }

    final int targetStart = state.normalizedPageStart + HomeState.pageSize;
    final int token = ++_activeLoadToken;
    _loadClassPage(className, pageStart: targetStart, token: token);
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
