import 'package:flutter/material.dart';

class HomeQueryPanel extends StatelessWidget {
  const HomeQueryPanel({
    super.key,
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
