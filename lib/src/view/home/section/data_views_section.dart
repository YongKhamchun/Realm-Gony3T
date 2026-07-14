import 'dart:async';
import 'dart:convert';

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

class HomeDataViewsPanel extends StatelessWidget {
  const HomeDataViewsPanel({
    super.key,
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
      initialIndex: 1,
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
                HomeJsonView(documents: documents),
                HomeTableView(documents: documents, columns: tableColumns),
                HomeInspectorView(documents: documents),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeJsonView extends StatefulWidget {
  const HomeJsonView({super.key, required this.documents});

  final List<Map<String, dynamic>> documents;

  @override
  State<HomeJsonView> createState() => _HomeJsonViewState();
}

class _HomeJsonViewState extends State<HomeJsonView> {
  late Future<String> _prettyFuture;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _prettyFuture = _buildPrettyJson(widget.documents);
  }

  @override
  void didUpdateWidget(covariant HomeJsonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.documents, widget.documents)) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 220), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _prettyFuture = _buildPrettyJson(widget.documents);
        });
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.documents.isEmpty) {
      return const Center(child: Text('No data found for this page'));
    }

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
            child: FutureBuilder<String>(
              future: _prettyFuture,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  );
                }

                return CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: SelectableText(
                        snapshot.data!,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class HomeTableView extends StatelessWidget {
  const HomeTableView({
    super.key,
    required this.documents,
    required this.columns,
  });

  final List<Map<String, dynamic>> documents;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('No data found for this query'));
    }

    final List<String> effectiveColumns = columns.isEmpty
        ? documents.first.keys
              .where((String key) => key != '_id')
              .toList(growable: false)
        : columns;
    const double cellWidth = 170;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tableWidth = (effectiveColumns.length * cellWidth)
            .toDouble();
        final double minWidth = constraints.maxWidth;

        return CustomScrollView(
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: tableWidth < minWidth ? minWidth : tableWidth,
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: _TableHeaderRow(columns: effectiveColumns),
                      ),
                      SliverList.builder(
                        itemCount: documents.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _TableDataRow(
                            rowIndex: index,
                            columns: effectiveColumns,
                            document: documents[index],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns});

  final List<String> columns;

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
        children: columns
            .map((String key) => _TableCell(text: key, isHeader: true))
            .toList(growable: false),
      ),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.rowIndex,
    required this.columns,
    required this.document,
  });

  final int rowIndex;
  final List<String> columns;
  final Map<String, dynamic> document;

  @override
  Widget build(BuildContext context) {
    final bool isEven = rowIndex.isEven;
    final Color bg = isEven
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceContainerLowest;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: columns
            .map((String key) => _TableCell(text: displayValue(document[key])))
            .toList(growable: false),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.text, this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: isHeader
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class HomeInspectorView extends ConsumerStatefulWidget {
  const HomeInspectorView({super.key, required this.documents});

  final List<Map<String, dynamic>> documents;

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
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                SizedBox(width: 150, child: Text('Key')),
                Expanded(child: Text('Value')),
                SizedBox(width: 90, child: Text('Type')),
              ],
            ),
          ),
        ),
        Expanded(
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
                  );
                }, childCount: widget.documents.length),
              ),
            ],
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
  });

  final String keyLabel;
  final dynamic value;
  final int depth;
  final String nodePath;

  List<Widget> _buildChildren() {
    final dynamic value = this.value;
    if (value is Map<String, dynamic>) {
      final List<Widget> items = <Widget>[];
      value.forEach((String key, dynamic childValue) {
        final String childPath = '$nodePath.$key';
        items.add(
          HomeInspectorNodeTile(
            key: ValueKey<String>(childPath),
            keyLabel: key,
            value: childValue,
            depth: depth + 1,
            nodePath: childPath,
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
          ),
        );
      }
      return items;
    }

    return const <Widget>[];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamic value = this.value;
    final bool isMap = value is Map<String, dynamic>;
    final bool isList = value is List<dynamic>;
    final bool isComplex = isMap || isList;

    if (!isComplex) {
      return HomeInspectorRow(
        keyLabel: keyLabel,
        valueLabel: displayValue(value),
        typeLabel: valueType(value),
        depth: depth,
      );
    }

    final bool isExpanded = ref.watch(
      inspectorTreeExpansionProvider.select(
        (Map<String, bool> state) => state[nodePath] ?? false,
      ),
    );

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 12 + depth * 14, right: 8),
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: isExpanded,
      onExpansionChanged: (bool expanded) {
        ref
            .read(inspectorTreeExpansionProvider.notifier)
            .setExpanded(nodePath, expanded);
      },
      title: Row(
        children: <Widget>[
          SizedBox(width: 150, child: Text(keyLabel)),
          Expanded(child: Text(displayValue(value))),
          SizedBox(width: 90, child: Text(valueType(value))),
        ],
      ),
      children: isExpanded ? _buildChildren() : const <Widget>[],
    );
  }
}

Future<String> _buildPrettyJson(List<Map<String, dynamic>> documents) {
  return Future<String>.delayed(Duration.zero, () {
    return const JsonEncoder.withIndent('  ').convert(toJsonSafe(documents));
  });
}

class HomeInspectorRow extends StatelessWidget {
  const HomeInspectorRow({
    super.key,
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

String safeJsonEncode(Object? value) {
  return jsonEncode(toJsonSafe(value));
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
