import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm_gony3t/realm_gony3T.dart';

final NotifierProvider<HomeNotifier, HomeState> homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

class HomeState {
  const HomeState({
    required this.documents,
    required this.query,
    required this.pageStart,
    required this.selectedIndex,
    required this.dataSourceLabel,
    required this.classes,
    required this.viewportWidth,
    required this.lastEncryptionKeyInput,
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
      pageStart: 0,
      selectedIndex: 0,
      dataSourceLabel: 'Mock data',
      classes: <RealmClassSummary>[],
      viewportWidth: 0,
      lastEncryptionKeyInput: '',
      openedSchemaName: null,
      loadError: null,
    );
  }

  static const int pageSize = 50;

  final List<Map<String, dynamic>> documents;
  final String query;
  final int pageStart;
  final int selectedIndex;
  final String dataSourceLabel;
  final List<RealmClassSummary> classes;
  final String? openedSchemaName;
  final String? loadError;
  final double viewportWidth;
  final String lastEncryptionKeyInput;

  HomeState copyWith({
    List<Map<String, dynamic>>? documents,
    String? query,
    int? pageStart,
    int? selectedIndex,
    String? dataSourceLabel,
    List<RealmClassSummary>? classes,
    String? openedSchemaName,
    Object? loadError = _noChange,
    double? viewportWidth,
    String? lastEncryptionKeyInput,
  }) {
    return HomeState(
      documents: documents ?? this.documents,
      query: query ?? this.query,
      pageStart: pageStart ?? this.pageStart,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      dataSourceLabel: dataSourceLabel ?? this.dataSourceLabel,
      classes: classes ?? this.classes,
      openedSchemaName: openedSchemaName ?? this.openedSchemaName,
      loadError: identical(loadError, _noChange)
          ? this.loadError
          : loadError as String?,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      lastEncryptionKeyInput:
          lastEncryptionKeyInput ?? this.lastEncryptionKeyInput,
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
    final int total = filteredDocuments.length;
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
    final List<Map<String, dynamic>> input = filteredDocuments;
    if (input.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final int start = normalizedPageStart;
    final int end = (start + pageSize).clamp(0, input.length);
    return input.sublist(start, end);
  }

  bool get canPrevPage => normalizedPageStart > 0;

  bool get canNextPage {
    final int total = filteredDocuments.length;
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
    final List<Map<String, dynamic>> docs = pagedDocuments;
    if (docs.isEmpty) {
      return 'Display 0 - 0';
    }
    return 'Display $normalizedPageStart - ${normalizedPageStart + docs.length}';
  }
}

class HomeNotifier extends Notifier<HomeState> {
  final RealmUserRepository _repository = RealmUserRepository();

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

  void updateLastEncryptionKeyInput(String input) {
    if (state.lastEncryptionKeyInput == input) {
      return;
    }
    state = state.copyWith(lastEncryptionKeyInput: input);
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
          ? const <Map<String, dynamic>>[]
          : _repository.readClassDocuments(initialClassName);

      state = state.copyWith(
        classes: classes,
        documents: loaded,
        query: '',
        pageStart: 0,
        selectedIndex: 0,
        loadError: null,
        dataSourceLabel: _fileNameFromPath(filePath),
        openedSchemaName: initialClassName,
      );
    } catch (e) {
      state = state.copyWith(
        loadError: 'Open failed: schema mismatch or unsupported file.\n$e',
      );
    }
  }

  void selectClass(String className) {
    try {
      final List<Map<String, dynamic>> loaded = _repository.readClassDocuments(
        className,
      );

      state = state.copyWith(
        documents: loaded,
        pageStart: 0,
        selectedIndex: 0,
        query: '',
        openedSchemaName: className,
        loadError: null,
      );
    } catch (e) {
      state = state.copyWith(loadError: 'Read class failed: $className\n$e');
    }
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

    state = state.copyWith(
      pageStart: state.normalizedPageStart - HomeState.pageSize,
      selectedIndex: 0,
    );
  }

  void goNextPage() {
    if (!state.canNextPage) {
      return;
    }

    state = state.copyWith(
      pageStart: state.normalizedPageStart + HomeState.pageSize,
      selectedIndex: 0,
    );
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
