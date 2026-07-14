import 'package:flutter/material.dart';

class HomeQueryPanel extends StatefulWidget {
  const HomeQueryPanel({
    super.key,
    required this.controller,
    required this.onRunQuery,
    required this.onClearQuery,
    required this.onOpenFile,
    required this.onOpenSettings,
    required this.dataSourceLabel,
    required this.loadError,
    required this.queryValidationError,
    required this.isQueryRunning,
  });

  final TextEditingController controller;
  final VoidCallback onRunQuery;
  final VoidCallback onClearQuery;
  final VoidCallback onOpenFile;
  final VoidCallback onOpenSettings;
  final String dataSourceLabel;
  final String? loadError;
  final String? queryValidationError;
  final bool isQueryRunning;

  @override
  State<HomeQueryPanel> createState() => _HomeQueryPanelState();
}

class _HomeQueryPanelState extends State<HomeQueryPanel> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo_gony3t.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Query Section', style: TextStyle(fontSize: 16)),
              const Spacer(),
              IconButton(
                tooltip: 'Open .realm file',
                onPressed: widget.onOpenFile,
                icon: const Icon(Icons.folder_open),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Data source: ${widget.dataSourceLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.loadError != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.loadError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: !widget.isQueryRunning,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    hintText: 'Try: name:alice && age>=30 && status=active',
                    prefixIcon: Icon(Icons.query_stats),
                  ),
                  onSubmitted: (_) => widget.onRunQuery(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: widget.isQueryRunning ? null : widget.onRunQuery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.isQueryRunning ? null : widget.onClearQuery,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
          if (widget.isQueryRunning) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: const <Widget>[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Running query on full dataset...'),
              ],
            ),
          ],
          if (widget.queryValidationError != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.queryValidationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
