import 'dart:convert';

import 'package:appv2/db/database_helper.dart';
import 'package:flutter/material.dart';

class DatabaseDebugScreen extends StatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  State<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  late Future<_DatabaseSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_DatabaseSnapshot> _loadSnapshot() async {
    final db = await DatabaseHelper.instance.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
      "ORDER BY name ASC",
    );

    final tableData = <_TableDump>[];
    for (final row in tables) {
      final tableName = (row['name'] ?? '').toString();
      if (tableName.isEmpty) continue;

      final escaped = tableName.replaceAll('"', '""');
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM "$escaped"',
      );
      final rawCount = countResult.first['count'];
      final totalRows = rawCount is int ? rawCount : (rawCount as num).toInt();

      final rows = await db.rawQuery('SELECT * FROM "$escaped" LIMIT 50');
      tableData.add(
        _TableDump(
          name: tableName,
          totalRows: totalRows,
          sampleRows: rows,
        ),
      );
    }

    return _DatabaseSnapshot(path: db.path, tables: tableData);
  }

  Future<void> _refresh() async {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
    await _snapshotFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: FutureBuilder<_DatabaseSnapshot>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load database: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data!;
          if (data.tables.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText('Path: ${data.path}'),
                  const SizedBox(height: 12),
                  const Text('No tables found.'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText('Path: ${data.path}'),
                ),
              ),
              const SizedBox(height: 8),
              ...data.tables.map(
                (table) => Card(
                  child: ExpansionTile(
                    title: Text(table.name),
                    subtitle: Text(
                      'Rows: ${table.totalRows} | Showing: ${table.sampleRows.length}',
                    ),
                    children: [
                      if (table.sampleRows.isEmpty)
                        const ListTile(title: Text('Empty table')),
                      ...table.sampleRows.map(
                        (row) => ListTile(
                          dense: true,
                          title: SelectableText(jsonEncode(row)),
                        ),
                      ),
                    ],
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

class _DatabaseSnapshot {
  const _DatabaseSnapshot({
    required this.path,
    required this.tables,
  });

  final String path;
  final List<_TableDump> tables;
}

class _TableDump {
  const _TableDump({
    required this.name,
    required this.totalRows,
    required this.sampleRows,
  });

  final String name;
  final int totalRows;
  final List<Map<String, Object?>> sampleRows;
}
