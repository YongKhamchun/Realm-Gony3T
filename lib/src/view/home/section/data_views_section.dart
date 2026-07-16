import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<InspectorTreeExpansionNotifier, Map<String, bool>>
inspectorTreeExpansionProvider =
    NotifierProvider<InspectorTreeExpansionNotifier, Map<String, bool>>(
      InspectorTreeExpansionNotifier.new,
    );

class InspectorTreeExpansionNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => <String, bool>{};

  void replaceAll(Map<String, bool> next) {
    state = Map<String, bool>.unmodifiable(next);
  }

  void setExpanded(String nodePath, bool expanded) {
    final Map<String, bool> next = <String, bool>{...state};
    if (expanded) {
      next[nodePath] = true;
    } else {
      next.remove(nodePath);
    }
    state = next;
  }
}

final NotifierProvider<_DataViewTabIndexNotifier, int>
_dataViewTabIndexProvider = NotifierProvider<_DataViewTabIndexNotifier, int>(
  _DataViewTabIndexNotifier.new,
);

class _DataViewTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    state = index;
  }
}

final NotifierProvider<_LoadedDataTabsNotifier, Set<int>>
_loadedDataTabsProvider = NotifierProvider<_LoadedDataTabsNotifier, Set<int>>(
  _LoadedDataTabsNotifier.new,
);

final NotifierProvider<_TableNestedResolveNotifier, bool>
_tableNestedResolveProvider =
    NotifierProvider<_TableNestedResolveNotifier, bool>(
      _TableNestedResolveNotifier.new,
    );

class _TableNestedResolveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) {
    state = value;
  }
}

final NotifierProvider<_InspectorLayoutNotifier, _InspectorLayoutState>
_inspectorLayoutProvider =
    NotifierProvider<_InspectorLayoutNotifier, _InspectorLayoutState>(
      _InspectorLayoutNotifier.new,
    );

class _InspectorLayoutState {
  const _InspectorLayoutState({
    required this.keyWidth,
    required this.isResizing,
    required this.lastResizeDx,
  });

  final double keyWidth;
  final bool isResizing;
  final double lastResizeDx;

  _InspectorLayoutState copyWith({
    double? keyWidth,
    bool? isResizing,
    double? lastResizeDx,
  }) {
    return _InspectorLayoutState(
      keyWidth: keyWidth ?? this.keyWidth,
      isResizing: isResizing ?? this.isResizing,
      lastResizeDx: lastResizeDx ?? this.lastResizeDx,
    );
  }
}

class _InspectorLayoutNotifier extends Notifier<_InspectorLayoutState> {
  static const double _minInspectorKeyWidth = 110;
  static const double _maxInspectorKeyWidth = 460;

  @override
  _InspectorLayoutState build() {
    return const _InspectorLayoutState(
      keyWidth: 150,
      isResizing: false,
      lastResizeDx: 0,
    );
  }

  void startResize(double dx) {
    state = state.copyWith(isResizing: true, lastResizeDx: dx);
  }

  void resizeTo(double dx) {
    if (!state.isResizing) {
      return;
    }

    final double delta = dx - state.lastResizeDx;
    final double nextWidth = (state.keyWidth + delta).clamp(
      _minInspectorKeyWidth,
      _maxInspectorKeyWidth,
    );
    state = state.copyWith(keyWidth: nextWidth, lastResizeDx: dx);
  }

  void stopResize() {
    if (!state.isResizing) {
      return;
    }
    state = state.copyWith(isResizing: false);
  }
}

final NotifierProvider<
  _InspectorNodeResolveNotifier,
  Map<String, _InspectorNodeResolveState>
>
_inspectorNodeResolveProvider =
    NotifierProvider<
      _InspectorNodeResolveNotifier,
      Map<String, _InspectorNodeResolveState>
    >(_InspectorNodeResolveNotifier.new);

class _InspectorNodeResolveState {
  const _InspectorNodeResolveState({
    required this.sourceIdentity,
    required this.isResolving,
    this.resolvedValue,
  });

  final int sourceIdentity;
  final bool isResolving;
  final Map<String, dynamic>? resolvedValue;

  _InspectorNodeResolveState copyWith({
    int? sourceIdentity,
    bool? isResolving,
    Map<String, dynamic>? resolvedValue,
  }) {
    return _InspectorNodeResolveState(
      sourceIdentity: sourceIdentity ?? this.sourceIdentity,
      isResolving: isResolving ?? this.isResolving,
      resolvedValue: resolvedValue ?? this.resolvedValue,
    );
  }
}

class _InspectorNodeResolveNotifier
    extends Notifier<Map<String, _InspectorNodeResolveState>> {
  @override
  Map<String, _InspectorNodeResolveState> build() =>
      <String, _InspectorNodeResolveState>{};

  void beginResolving(String nodePath, int sourceIdentity) {
    final _InspectorNodeResolveState? current = state[nodePath];
    final _InspectorNodeResolveState next = _InspectorNodeResolveState(
      sourceIdentity: sourceIdentity,
      isResolving: true,
      resolvedValue: current?.sourceIdentity == sourceIdentity
          ? current?.resolvedValue
          : null,
    );
    state = <String, _InspectorNodeResolveState>{...state, nodePath: next};
  }

  void finishResolving(
    String nodePath, {
    required int sourceIdentity,
    Map<String, dynamic>? resolvedValue,
  }) {
    final _InspectorNodeResolveState next = _InspectorNodeResolveState(
      sourceIdentity: sourceIdentity,
      isResolving: false,
      resolvedValue: resolvedValue,
    );
    state = <String, _InspectorNodeResolveState>{...state, nodePath: next};
  }

  void clearAll() {
    if (state.isEmpty) {
      return;
    }
    state = <String, _InspectorNodeResolveState>{};
  }
}

class _LoadedDataTabsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{0};

  void markLoaded(int index) {
    if (state.contains(index)) {
      return;
    }
    state = <int>{...state, index};
  }
}

class HomeDataViewsPanel extends ConsumerWidget {
  const HomeDataViewsPanel({
    super.key,
    required this.documents,
    required this.tableColumns,
    required this.displayRangeLabel,
    required this.currentDepth,
    required this.isLoading,
    required this.depthOptions,
    required this.onSelectDepth,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.onResolveLazyObjectRef,
  });

  final List<Map<String, dynamic>> documents;
  final List<String> tableColumns;
  final String displayRangeLabel;
  final int currentDepth;
  final bool isLoading;
  final List<int> depthOptions;
  final ValueChanged<int> onSelectDepth;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Future<Map<String, dynamic>?> Function(int lazyRef)
  onResolveLazyObjectRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int activeTabIndex = ref.watch(_dataViewTabIndexProvider);
    final Set<int> loadedTabs = ref.watch(_loadedDataTabsProvider);
    final List<_TableScope> tableScopes = ref.watch(
      _tableDrillProvider.select((_TableDrillState s) => s.scopes),
    );

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 980;

          return Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                displayRangeLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (activeTabIndex == 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: _TableLayerInlinePath(
                                    scopes: tableScopes,
                                    onTapScope: (int index) {
                                      ref
                                          .read(_tableDrillProvider.notifier)
                                          .navigateToScope(index);
                                    },
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SizedBox(
                                      height: 30,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: currentDepth,
                                            isDense: true,
                                            onChanged: isLoading
                                                ? null
                                                : (int? value) {
                                                    if (value == null) {
                                                      return;
                                                    }
                                                    onSelectDepth(value);
                                                  },
                                            items: depthOptions
                                                .map(
                                                  (int depth) =>
                                                      DropdownMenuItem<int>(
                                                        value: depth,
                                                        child: Text(
                                                          depth < 0
                                                              ? 'Depth Full'
                                                              : 'Depth $depth',
                                                        ),
                                                      ),
                                                )
                                                .toList(growable: false),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: isLoading || !canPrev
                                        ? null
                                        : onPrev,
                                    child: const Text('Prev'),
                                  ),
                                  OutlinedButton(
                                    onPressed: isLoading || !canNext
                                        ? null
                                        : onNext,
                                    child: const Text('Next'),
                                  ),
                                  TabBar(
                                    isScrollable: true,
                                    onTap: (int index) {
                                      ref
                                          .read(
                                            _dataViewTabIndexProvider.notifier,
                                          )
                                          .select(index);
                                      ref
                                          .read(
                                            _loadedDataTabsProvider.notifier,
                                          )
                                          .markLoaded(index);
                                    },
                                    tabs: const <Tab>[
                                      Tab(text: 'Table'),
                                      Tab(text: 'Inspector'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: <Widget>[
                              Expanded(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      displayRangeLabel,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    if (activeTabIndex == 0)
                                      _TableLayerInlinePath(
                                        scopes: tableScopes,
                                        onTapScope: (int index) {
                                          ref
                                              .read(
                                                _tableDrillProvider.notifier,
                                              )
                                              .navigateToScope(index);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SizedBox(
                                  height: 30,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: currentDepth,
                                        isDense: true,
                                        onChanged: isLoading
                                            ? null
                                            : (int? value) {
                                                if (value == null) {
                                                  return;
                                                }
                                                onSelectDepth(value);
                                              },
                                        items: depthOptions
                                            .map(
                                              (int depth) =>
                                                  DropdownMenuItem<int>(
                                                    value: depth,
                                                    child: Text(
                                                      depth < 0
                                                          ? 'Depth Full'
                                                          : 'Depth $depth',
                                                    ),
                                                  ),
                                            )
                                            .toList(growable: false),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: isLoading || !canPrev
                                    ? null
                                    : onPrev,
                                child: const Text('Prev'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed:
                                    isLoading || activeTabIndex == 0 || !canNext
                                    ? null
                                    : onNext,
                                child: const Text('Next'),
                              ),
                              const SizedBox(width: 12),
                              TabBar(
                                isScrollable: true,
                                onTap: (int index) {
                                  ref
                                      .read(_dataViewTabIndexProvider.notifier)
                                      .select(index);
                                  ref
                                      .read(_loadedDataTabsProvider.notifier)
                                      .markLoaded(index);
                                },
                                tabs: const <Tab>[
                                  Tab(text: 'Table'),
                                  Tab(text: 'Inspector'),
                                ],
                              ),
                            ],
                          ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: activeTabIndex,
                      children: <Widget>[
                        loadedTabs.contains(0)
                            ? HomeTableView(
                                key: const PageStorageKey<String>(
                                  'home-data-table',
                                ),
                                documents: documents,
                                columns: tableColumns,
                                onResolveLazyObjectRef: onResolveLazyObjectRef,
                              )
                            : const _DeferredTabPlaceholder(
                                label: 'Open Table tab to load records',
                              ),
                        loadedTabs.contains(1)
                            ? HomeInspectorView(
                                key: const PageStorageKey<String>(
                                  'home-data-inspector',
                                ),
                                documents: documents,
                                onResolveLazyObjectRef: onResolveLazyObjectRef,
                              )
                            : const _DeferredTabPlaceholder(
                                label: 'Open Inspector tab to inspect tree',
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.55),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text('Loading data...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DeferredTabPlaceholder extends StatelessWidget {
  const _DeferredTabPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class HomeTableView extends ConsumerStatefulWidget {
  const HomeTableView({
    super.key,
    required this.documents,
    required this.columns,
    required this.onResolveLazyObjectRef,
  });

  final List<Map<String, dynamic>> documents;
  final List<String> columns;
  final Future<Map<String, dynamic>?> Function(int lazyRef)
  onResolveLazyObjectRef;

  @override
  ConsumerState<HomeTableView> createState() => _HomeTableViewState();
}

class _HomeTableViewState extends ConsumerState<HomeTableView> {
  _TableDrillRequest? _pendingRootRequest;
  bool _isRootSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _syncRootScope();
  }

  @override
  void didUpdateWidget(covariant HomeTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.documents, widget.documents) ||
        !listEquals(oldWidget.columns, widget.columns)) {
      _syncRootScope();
    }
  }

  void _syncRootScope() {
    _pendingRootRequest = _TableDrillRequest(
      rootRows: widget.documents,
      rootColumns: widget.columns,
    );

    if (_isRootSyncScheduled) {
      return;
    }

    _isRootSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isRootSyncScheduled = false;
      if (!mounted) {
        return;
      }

      final _TableDrillRequest? request = _pendingRootRequest;
      _pendingRootRequest = null;
      if (request == null) {
        return;
      }

      ref.read(_tableDrillProvider.notifier).setRoot(request);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _TableDrillState state = ref.watch(_tableDrillProvider);
    final _TableScope scope = state.scopes.last;
    final List<Map<String, dynamic>> rows = scope.rows;

    return rows.isEmpty
        ? const Center(child: Text('No data found for this query'))
        : LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double tableWidth = state.columnWidths.fold<double>(
                0,
                (double sum, double width) => sum + width,
              );
              final double minWidth = constraints.maxWidth;
              final double effectiveTableWidth = tableWidth < minWidth
                  ? minWidth
                  : tableWidth;

              return CustomScrollView(
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        width: effectiveTableWidth,
                        child: SelectionArea(
                          child: CustomScrollView(
                            physics: const ClampingScrollPhysics(),
                            slivers: <Widget>[
                              SliverToBoxAdapter(
                                child: _TableHeaderRow(
                                  columns: state.effectiveColumns,
                                  columnWidths: state.columnWidths,
                                  onResizeColumn: (int index, double deltaX) {
                                    ref
                                        .read(_tableDrillProvider.notifier)
                                        .resizeColumn(index, deltaX);
                                  },
                                ),
                              ),
                              SliverList.builder(
                                itemCount: rows.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return _TableDataRow(
                                    rowIndex: index,
                                    columns: state.effectiveColumns,
                                    columnWidths: state.columnWidths,
                                    document: rows[index],
                                    onOpenNested:
                                        (
                                          int rowIndex,
                                          String column,
                                          dynamic value,
                                        ) {
                                          unawaited(
                                            _openNestedValue(
                                              rowIndex,
                                              column,
                                              value,
                                            ),
                                          );
                                        },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }

  Future<void> _openNestedValue(
    int rowIndex,
    String column,
    dynamic value,
  ) async {
    final dynamic resolved = await _resolveLazyValueIfNeeded(value);
    if (!_isMeaningfullyExpandable(resolved)) {
      return;
    }
    ref
        .read(_tableDrillProvider.notifier)
        .openNestedTable(rowIndex, column, resolved);
  }

  Future<dynamic> _resolveLazyValueIfNeeded(dynamic value) async {
    final int? lazyRef = _lazyRefFromNode(value);
    if (lazyRef == null) {
      return value;
    }

    ref.read(_tableNestedResolveProvider.notifier).setBusy(true);

    try {
      final Map<String, dynamic>? resolved = await widget
          .onResolveLazyObjectRef(lazyRef);
      if (resolved == null) {
        return value;
      }
      return _attachLazyMetaAfterResolve(original: value, resolved: resolved);
    } finally {
      ref.read(_tableNestedResolveProvider.notifier).setBusy(false);
    }
  }
}

final NotifierProvider<_TableDrillNotifier, _TableDrillState>
_tableDrillProvider = NotifierProvider<_TableDrillNotifier, _TableDrillState>(
  _TableDrillNotifier.new,
);

class _TableDrillRequest {
  const _TableDrillRequest({required this.rootRows, required this.rootColumns});

  final List<Map<String, dynamic>> rootRows;
  final List<String> rootColumns;

  @override
  bool operator ==(Object other) {
    return other is _TableDrillRequest &&
        identical(rootRows, other.rootRows) &&
        identical(rootColumns, other.rootColumns);
  }

  @override
  int get hashCode =>
      Object.hash(identityHashCode(rootRows), identityHashCode(rootColumns));
}

class _TableDrillState {
  const _TableDrillState({
    required this.scopes,
    required this.effectiveColumns,
    required this.columnWidths,
  });

  final List<_TableScope> scopes;
  final List<String> effectiveColumns;
  final List<double> columnWidths;
}

class _TableDrillNotifier extends Notifier<_TableDrillState> {
  static const double _minColumnWidth = 120;
  static const double _maxColumnWidth = 720;
  static const String _selfFallbackColumnKey = '__self__';

  @override
  _TableDrillState build() {
    return const _TableDrillState(
      scopes: <_TableScope>[
        _TableScope(
          label: 'Root',
          rows: <Map<String, dynamic>>[],
          preferredColumns: <String>[],
        ),
      ],
      effectiveColumns: <String>[],
      columnWidths: <double>[],
    );
  }

  void setRoot(_TableDrillRequest request) {
    state = _buildStateForScopes(<_TableScope>[
      _TableScope(
        label: 'Root',
        rows: request.rootRows,
        preferredColumns: request.rootColumns,
      ),
    ]);
  }

  void resizeColumn(int index, double deltaX) {
    if (index < 0 || index >= state.columnWidths.length) {
      return;
    }

    final List<double> nextWidths = List<double>.of(state.columnWidths);
    final double next = (nextWidths[index] + deltaX).clamp(
      _minColumnWidth,
      _maxColumnWidth,
    );
    nextWidths[index] = next;

    state = _TableDrillState(
      scopes: state.scopes,
      effectiveColumns: state.effectiveColumns,
      columnWidths: List<double>.unmodifiable(nextWidths),
    );
  }

  void openNestedTable(int rowIndex, String column, dynamic value) {
    final List<Map<String, dynamic>>? nextRows = _rowsFromNestedValue(value);
    if (nextRows == null) {
      return;
    }

    final String label = '#$rowIndex.$column';
    final List<_TableScope> nextScopes = List<_TableScope>.of(state.scopes)
      ..add(
        _TableScope(label: label, rows: nextRows, preferredColumns: const []),
      );

    state = _buildStateForScopes(nextScopes);
  }

  void navigateToScope(int index) {
    if (index < 0 || index >= state.scopes.length) {
      return;
    }

    final List<_TableScope> nextScopes = state.scopes
        .take(index + 1)
        .toList(growable: true);
    state = _buildStateForScopes(nextScopes);
  }

  _TableDrillState _buildStateForScopes(List<_TableScope> scopes) {
    final _TableScope current = scopes.last;
    final List<String> effectiveColumns = _resolveColumns(
      current.rows,
      current.preferredColumns,
    );

    final List<double> widths = effectiveColumns
        .map((String column) => _estimateColumnWidth(column, current.rows))
        .toList(growable: false);

    return _TableDrillState(
      scopes: List<_TableScope>.unmodifiable(scopes),
      effectiveColumns: List<String>.unmodifiable(effectiveColumns),
      columnWidths: List<double>.unmodifiable(widths),
    );
  }

  List<String> _resolveColumns(
    List<Map<String, dynamic>> rows,
    List<String> preferred,
  ) {
    if (rows.isEmpty) {
      return preferred;
    }

    if (preferred.isNotEmpty) {
      return preferred;
    }

    final Set<String> ordered = <String>{};
    for (final Map<String, dynamic> row in rows) {
      ordered.addAll(
        row.keys.where(
          (String key) => key != '_id' && !_isInternalMetaKey(key),
        ),
      );
    }

    if (ordered.isEmpty && rows.isNotEmpty) {
      return const <String>[_selfFallbackColumnKey];
    }

    return ordered.toList(growable: false);
  }

  List<Map<String, dynamic>>? _rowsFromNestedValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return <Map<String, dynamic>>[value];
    }

    if (value is Map) {
      final Map<String, dynamic> casted = <String, dynamic>{};
      value.forEach((dynamic k, dynamic v) {
        casted['$k'] = v;
      });
      return <Map<String, dynamic>>[casted];
    }

    if (value is List<dynamic>) {
      return List<Map<String, dynamic>>.generate(value.length, (int i) {
        final dynamic item = value[i];
        if (item is Map<String, dynamic>) {
          return <String, dynamic>{'_index': i, ...item};
        }
        if (item is Map) {
          final Map<String, dynamic> casted = <String, dynamic>{'_index': i};
          item.forEach((dynamic k, dynamic v) {
            casted['$k'] = v;
          });
          return casted;
        }
        return <String, dynamic>{'_index': i, 'value': item};
      });
    }

    return null;
  }

  double _estimateColumnWidth(String column, List<Map<String, dynamic>> rows) {
    int maxChars = column.length;
    for (final Map<String, dynamic> row in rows) {
      final dynamic cellValue = column == _selfFallbackColumnKey
          ? row
          : row[column];
      final int len = displayValue(cellValue).length;
      if (len > maxChars) {
        maxChars = len;
      }
    }

    final double estimated = maxChars * 7.2 + 28;
    return estimated.clamp(170, 520).toDouble();
  }
}

class _TableScope {
  const _TableScope({
    required this.label,
    required this.rows,
    required this.preferredColumns,
  });

  final String label;
  final List<Map<String, dynamic>> rows;
  final List<String> preferredColumns;
}

class _TableLayerInlinePath extends StatelessWidget {
  const _TableLayerInlinePath({required this.scopes, required this.onTapScope});

  final List<_TableScope> scopes;
  final ValueChanged<int> onTapScope;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(scopes.length, (int index) {
          final bool isLast = index == scopes.length - 1;
          return Row(
            children: <Widget>[
              TextButton(
                onPressed: isLast ? null : () => onTapScope(index),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 24),
                ),
                child: Text(scopes[index].label),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.chevron_right, size: 14),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({
    required this.columns,
    required this.columnWidths,
    required this.onResizeColumn,
  });

  final List<String> columns;
  final List<double> columnWidths;
  final void Function(int index, double deltaX) onResizeColumn;

  @override
  Widget build(BuildContext context) {
    final Color bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: List<Widget>.generate(columns.length, (int index) {
          return _ResizableHeaderCell(
            text: _displayTableColumnName(columns[index]),
            width: columnWidths[index],
            onResize: (double deltaX) => onResizeColumn(index, deltaX),
          );
        }),
      ),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.rowIndex,
    required this.columns,
    required this.columnWidths,
    required this.document,
    required this.onOpenNested,
  });

  final int rowIndex;
  final List<String> columns;
  final List<double> columnWidths;
  final Map<String, dynamic> document;
  final void Function(int rowIndex, String column, dynamic value) onOpenNested;

  @override
  Widget build(BuildContext context) {
    final bool isEven = rowIndex.isEven;
    final Color bg = isEven
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceContainerLowest;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: List<Widget>.generate(columns.length, (int index) {
          final String key = columns[index];
          final dynamic cellValue =
              key == _TableDrillNotifier._selfFallbackColumnKey
              ? document
              : document[key];
          return _TableCell(
            value: cellValue,
            width: columnWidths[index],
            onOpenNested: (dynamic value) => onOpenNested(rowIndex, key, value),
          );
        }),
      ),
    );
  }
}

String _displayTableColumnName(String column) {
  if (column == _TableDrillNotifier._selfFallbackColumnKey) {
    return 'value';
  }
  return column;
}

class _ResizableHeaderCell extends StatefulWidget {
  const _ResizableHeaderCell({
    required this.text,
    required this.width,
    required this.onResize,
  });

  final String text;
  final double width;
  final ValueChanged<double> onResize;

  @override
  State<_ResizableHeaderCell> createState() => _ResizableHeaderCellState();
}

class _ResizableHeaderCellState extends State<_ResizableHeaderCell> {
  bool _isDragging = false;
  double _lastDx = 0;

  void _onPointerDown(PointerDownEvent event) {
    _isDragging = true;
    _lastDx = event.position.dx;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging) {
      return;
    }
    final double delta = event.position.dx - _lastDx;
    _lastDx = event.position.dx;
    widget.onResize(delta);
  }

  void _stopDragging() {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
              child: Text(
                widget.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: (_) => _stopDragging(),
              onPointerCancel: (_) => _stopDragging(),
              child: Container(
                width: 14,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Icon(
                  Icons.drag_indicator,
                  size: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.value,
    required this.width,
    required this.onOpenNested,
  });

  final dynamic value;
  final double width;
  final ValueChanged<dynamic> onOpenNested;

  @override
  Widget build(BuildContext context) {
    final bool isExpandable = _isMeaningfullyExpandable(value);
    final String text = displayValue(value);

    return SizedBox(
      width: width,
      child: isExpandable
          ? InkWell(
              onTap: () => onOpenNested(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
    );
  }
}

bool _isMeaningfullyExpandable(dynamic value) {
  if (value is List<dynamic>) {
    return value.isNotEmpty;
  }

  if (value is Map<String, dynamic>) {
    if (_lazyRefFromNode(value) != null) {
      return true;
    }

    for (final String key in value.keys) {
      if (!_isInternalMetaKey(key)) {
        return true;
      }
    }

    return false;
  }

  return false;
}

class HomeInspectorView extends ConsumerStatefulWidget {
  const HomeInspectorView({
    super.key,
    required this.documents,
    required this.onResolveLazyObjectRef,
  });

  final List<Map<String, dynamic>> documents;
  final Future<Map<String, dynamic>?> Function(int lazyRef)
  onResolveLazyObjectRef;

  @override
  ConsumerState<HomeInspectorView> createState() => _HomeInspectorViewState();
}

class _HomeInspectorViewState extends ConsumerState<HomeInspectorView> {
  @override
  void initState() {
    super.initState();
    _scheduleCollapseAll();
  }

  @override
  void didUpdateWidget(covariant HomeInspectorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.documents, widget.documents)) {
      _scheduleCollapseAll();
    }
  }

  void _scheduleCollapseAll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref
          .read(inspectorTreeExpansionProvider.notifier)
          .replaceAll(const <String, bool>{});
      ref.read(_inspectorNodeResolveProvider.notifier).clearAll();
    });
  }

  void _startResize(PointerDownEvent event) {
    ref.read(_inspectorLayoutProvider.notifier).startResize(event.position.dx);
  }

  void _resizeKeyColumn(PointerMoveEvent event) {
    ref.read(_inspectorLayoutProvider.notifier).resizeTo(event.position.dx);
  }

  void _stopResize(_) {
    ref.read(_inspectorLayoutProvider.notifier).stopResize();
  }

  @override
  Widget build(BuildContext context) {
    final _InspectorLayoutState layout = ref.watch(_inspectorLayoutProvider);

    if (widget.documents.isEmpty) {
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
            child: Row(
              children: <Widget>[
                SizedBox(width: layout.keyWidth, child: const Text('Key')),
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Listener(
                    onPointerDown: _startResize,
                    onPointerMove: _resizeKeyColumn,
                    onPointerUp: _stopResize,
                    onPointerCancel: _stopResize,
                    child: Container(
                      width: 14,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(child: Text('Value')),
                const SizedBox(width: 90, child: Text('Type')),
              ],
            ),
          ),
        ),
        Expanded(
          child: SelectionArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final Map<String, dynamic> doc = widget.documents[index];
                    final String key = '#$index';
                    return HomeInspectorNodeTile(
                      key: ValueKey<String>(key),
                      keyLabel: key,
                      value: doc,
                      depth: 0,
                      nodePath: key,
                      keyColumnWidth: layout.keyWidth,
                      onResolveLazyObjectRef: widget.onResolveLazyObjectRef,
                    );
                  }, childCount: widget.documents.length),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HomeInspectorNodeTile extends ConsumerWidget {
  const HomeInspectorNodeTile({
    super.key,
    required this.keyLabel,
    required this.value,
    required this.depth,
    required this.nodePath,
    required this.keyColumnWidth,
    required this.onResolveLazyObjectRef,
  });

  final String keyLabel;
  final dynamic value;
  final int depth;
  final String nodePath;
  final double keyColumnWidth;
  final Future<Map<String, dynamic>?> Function(int lazyRef)
  onResolveLazyObjectRef;

  Future<void> _resolveIfNeeded(
    WidgetRef ref,
    _InspectorNodeResolveState? resolveState,
  ) async {
    final dynamic effectiveValue = resolveState?.resolvedValue ?? value;
    final int? lazyRef = _lazyRefFromNode(effectiveValue);
    if (lazyRef == null || (resolveState?.isResolving ?? false)) {
      return;
    }

    final int sourceIdentity = identityHashCode(value);
    ref
        .read(_inspectorNodeResolveProvider.notifier)
        .beginResolving(nodePath, sourceIdentity);

    try {
      final Map<String, dynamic>? resolved = await onResolveLazyObjectRef(
        lazyRef,
      );
      if (resolved == null) {
        ref
            .read(_inspectorNodeResolveProvider.notifier)
            .finishResolving(nodePath, sourceIdentity: sourceIdentity);
        return;
      }

      final Map<String, dynamic> attached = _attachLazyMetaAfterResolve(
        original: effectiveValue,
        resolved: resolved,
      );
      ref
          .read(_inspectorNodeResolveProvider.notifier)
          .finishResolving(
            nodePath,
            sourceIdentity: sourceIdentity,
            resolvedValue: attached,
          );
    } finally {
      final _InspectorNodeResolveState? latest = ref.read(
        _inspectorNodeResolveProvider.select(
          (Map<String, _InspectorNodeResolveState> m) => m[nodePath],
        ),
      );
      if (latest?.isResolving ?? false) {
        ref
            .read(_inspectorNodeResolveProvider.notifier)
            .finishResolving(nodePath, sourceIdentity: sourceIdentity);
      }
    }
  }

  List<Widget> _buildChildren(dynamic value) {
    if (value is Map<String, dynamic>) {
      final List<Widget> items = <Widget>[];
      value.forEach((String key, dynamic childValue) {
        if (_isInternalMetaKey(key)) {
          return;
        }
        final String childPath = '$nodePath.$key';
        items.add(
          HomeInspectorNodeTile(
            key: ValueKey<String>(childPath),
            keyLabel: key,
            value: childValue,
            depth: depth + 1,
            nodePath: childPath,
            keyColumnWidth: keyColumnWidth,
            onResolveLazyObjectRef: onResolveLazyObjectRef,
          ),
        );
      });
      return items;
    }

    if (value is List<dynamic>) {
      final List<Widget> items = <Widget>[];
      for (int i = 0; i < value.length; i++) {
        final String childPath = '$nodePath[$i]';
        items.add(
          HomeInspectorNodeTile(
            key: ValueKey<String>(childPath),
            keyLabel: '[$i]',
            value: value[i],
            depth: depth + 1,
            nodePath: childPath,
            keyColumnWidth: keyColumnWidth,
            onResolveLazyObjectRef: onResolveLazyObjectRef,
          ),
        );
      }
      return items;
    }

    return const <Widget>[];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int sourceIdentity = identityHashCode(value);
    final _InspectorNodeResolveState? resolveState = ref.watch(
      _inspectorNodeResolveProvider.select(
        (Map<String, _InspectorNodeResolveState> m) => m[nodePath],
      ),
    );

    final bool stateMatchesSource =
        resolveState?.sourceIdentity == sourceIdentity;
    final dynamic currentValue = stateMatchesSource
        ? (resolveState?.resolvedValue ?? value)
        : value;
    final bool isResolving =
        stateMatchesSource && (resolveState?.isResolving ?? false);

    final bool isMap = currentValue is Map<String, dynamic>;
    final bool isList = currentValue is List<dynamic>;
    final bool isComplex = isMap || isList;

    if (!isComplex) {
      return HomeInspectorRow(
        keyLabel: keyLabel,
        valueLabel: displayValue(currentValue),
        typeLabel: valueType(currentValue),
        depth: depth,
        keyColumnWidth: keyColumnWidth,
      );
    }

    final bool isExpanded = ref.watch(
      inspectorTreeExpansionProvider.select(
        (Map<String, bool> state) => state[nodePath] ?? false,
      ),
    );

    return ExpansionTile(
      key: PageStorageKey<String>('inspector-expand-$nodePath'),
      tilePadding: EdgeInsets.only(left: 12 + depth * 14, right: 8),
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: isExpanded,
      onExpansionChanged: (bool expanded) {
        if (expanded) {
          unawaited(_resolveIfNeeded(ref, resolveState));
        }
        ref
            .read(inspectorTreeExpansionProvider.notifier)
            .setExpanded(nodePath, expanded);
      },
      title: Row(
        children: <Widget>[
          SizedBox(
            width: keyColumnWidth,
            child: Text(keyLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              isResolving ? 'Loading...' : displayValue(currentValue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 90, child: Text(valueType(currentValue))),
        ],
      ),
      children: isExpanded ? _buildChildren(currentValue) : const <Widget>[],
    );
  }
}

class HomeInspectorRow extends StatelessWidget {
  const HomeInspectorRow({
    super.key,
    required this.keyLabel,
    required this.valueLabel,
    required this.typeLabel,
    required this.depth,
    required this.keyColumnWidth,
  });

  final String keyLabel;
  final String valueLabel;
  final String typeLabel;
  final int depth;
  final double keyColumnWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12 + depth * 14, 8, 8, 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: keyColumnWidth,
            child: Text(keyLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 20),
          Expanded(child: Text(valueLabel)),
          SizedBox(width: 90, child: Text(typeLabel)),
        ],
      ),
    );
  }
}

String valueType(dynamic value) {
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

String displayValue(dynamic value) {
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

int? _lazyRefFromNode(dynamic value) {
  if (value is! Map) {
    return null;
  }
  final dynamic truncated = value['_truncated'];
  final dynamic rawRef = value['_lazyRef'];
  final bool lazyExpandable = value['_lazyExpandable'] == true;
  if ((truncated != true && !lazyExpandable) || rawRef == null) {
    return null;
  }
  if (rawRef is int) {
    return rawRef;
  }
  if (rawRef is num) {
    return rawRef.toInt();
  }
  return int.tryParse('$rawRef');
}

Map<String, dynamic> _attachLazyMetaAfterResolve({
  required dynamic original,
  required Map<String, dynamic> resolved,
}) {
  if (original is! Map) {
    return resolved;
  }

  final dynamic lazyRef = original['_lazyRef'];
  if (lazyRef == null) {
    return resolved;
  }

  return <String, dynamic>{
    ...resolved,
    '_lazyRef': lazyRef,
    '_lazyClass': original['_lazyClass'],
    '_lazyExpandable': true,
  };
}

bool _isInternalMetaKey(String key) {
  return key == '_lazyRef' ||
      key == '_lazyClass' ||
      key == '_lazyExpandable' ||
      key == '_truncated' ||
      key == '_reason';
}

Object? toJsonSafe(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }

  if (value is DateTime) {
    return value.toIso8601String();
  }

  if (value is Map) {
    final Map<String, dynamic> output = <String, dynamic>{};
    value.forEach((dynamic key, dynamic val) {
      output['$key'] = toJsonSafe(val);
    });
    return output;
  }

  if (value is Iterable) {
    return value
        .map((Object? item) => toJsonSafe(item))
        .toList(growable: false);
  }

  return value.toString();
}
