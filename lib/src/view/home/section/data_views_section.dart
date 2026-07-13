import 'dart:convert';

import 'package:flutter/material.dart';

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

class HomeJsonView extends StatelessWidget {
  const HomeJsonView({super.key, required this.documents});

  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(child: Text('No data found for this page'));
    }

    final String pretty = const JsonEncoder.withIndent(
      '  ',
    ).convert(toJsonSafe(documents));

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

class HomeInspectorView extends StatelessWidget {
  const HomeInspectorView({super.key, required this.documents});

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
          child: ListView(
            children: List<Widget>.generate(documents.length, (int index) {
              final Map<String, dynamic> doc = documents[index];
              final String key = doc.containsKey('_id')
                  ? '#$index (${doc['_id']})'
                  : '#$index';
              return HomeInspectorNodeTile(keyLabel: key, value: doc, depth: 0);
            }),
          ),
        ),
      ],
    );
  }
}

class HomeInspectorNodeTile extends StatelessWidget {
  const HomeInspectorNodeTile({
    super.key,
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
      return HomeInspectorRow(
        keyLabel: keyLabel,
        valueLabel: displayValue(value),
        typeLabel: valueType(value),
        depth: depth,
      );
    }

    final List<Widget> children = <Widget>[];
    if (isMap) {
      final Map<String, dynamic> map = value as Map<String, dynamic>;
      map.forEach((String key, dynamic childValue) {
        children.add(
          HomeInspectorNodeTile(
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
          HomeInspectorNodeTile(
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
          Expanded(child: Text(displayValue(value))),
          SizedBox(width: 90, child: Text(valueType(value))),
        ],
      ),
      children: children,
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
