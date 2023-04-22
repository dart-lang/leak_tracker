import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leak_tracker/leak_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autosnapshotting Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Autosnapshotting Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final _allocations = <List<DateTime>>[];

class _MyHomePageState extends State<MyHomePage> {
  final _snapshots = <SnapshotRecord>[];

  void _allocateMemory() {
    setState(() {
      _allocations.add(List.generate(1000000, (_) => DateTime.now()));
    });
  }

  @override
  void initState() {
    super.initState();
    autoSnapshotOnMemoryOveruse(
      config: AutoSnapshottingConfig(onSnapshot: _handleSnapshot),
    );
  }

  void _handleSnapshot(SnapshotRecord record) {
    setState(() {
      _snapshots.add(record);
    });
  }

  String _formatSize(int bytes) {
    final formatter = NumberFormat('#,###,000');
    final megaBytes = bytes / 1024 / 1024;
    return '${formatter.format(bytes)} (${formatter.format(megaBytes)} MB)';
  }

  String _formatSnapshots() {
    return _snapshots.map((snapshot) {
      final size = _formatSize(snapshot.rss);
      final time = DateFormat('HH:mm:ss').format(snapshot.timestamp);
      return '$time : ${snapshot.fileName} : $size';
    }).join('/n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Current RSS: ${_formatSize(ProcessInfo.currentRss)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Taken snapshots:\n${_formatSnapshots()}',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _allocateMemory,
        tooltip: 'Allocate more memory',
        child: const Icon(Icons.add),
      ),
    );
  }
}
