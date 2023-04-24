import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leak_tracker/leak_tracker.dart';

const memoryThresholdMb = 400;
const memoryStepMb = 100;

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
  State<MyHomePage> createState() => MyHomePageState();
}

final _allocations = <List<DateTime>>[];

class MyHomePageState extends State<MyHomePage> {
  final _formatter = NumberFormat('#,###,000');
  late final String _configInfo;
  final snapshots = <SnapshotRecord>[];
  int lastRss = 0;
  late String snapshotsFolderName;

  void _allocateMemory() {
    setState(() {
      _allocations.add(List.generate(1000000, (_) => DateTime.now()));
      lastRss = ProcessInfo.currentRss;
    });
  }

  @override
  void initState() {
    super.initState();
    snapshotsFolderName = 'snapshots_$pid';
    final config = AutoSnapshottingConfig(
      onSnapshot: _handleSnapshot,
      thresholdMb: memoryThresholdMb,
      stepMb: memoryStepMb,
      folderSizeLimitMb: 500,
      folder: snapshotsFolderName,
    );

    _initConfigInfo(config);
    autoSnapshotOnMemoryOveruse(config: config);
  }

  void _initConfigInfo(AutoSnapshottingConfig config) {
    final stepsMb = config.stepMb;
    _configInfo = 'interval: ${config.interval}\n'
        'minDelayBetweenSnapshots: ${config.minDelayBetweenSnapshots}\n'
        'folder: ${config.folder}\n'
        'folderAbsolute: ${config.folderAbsolute}\n'
        'thresholdMb: ${_formatter.format(config.thresholdMb)}\n'
        'folderSizeLimitMb: ${_formatter.format(config.folderSizeLimitMb)}\n'
        'stepMb: ${stepsMb == null ? 'null' : _formatter.format(stepsMb)}\n';
  }

  void _handleSnapshot(SnapshotRecord record) {
    setState(() {
      snapshots.add(record);
    });
  }

  String _formatSize(int bytes) {
    final megaBytes = bytes / 1024 / 1024;
    return '${_formatter.format(bytes)} (${_formatter.format(megaBytes)} MB)';
  }

  String _formatSnapshots() {
    return snapshots.map((snapshot) {
      final time = DateFormat('HH:mm:ss').format(snapshot.timestamp);
      return '$time : ${snapshot.fileName}';
    }).join('\n');
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
              '-- Auto-Snapshotting Configuration --\n$_configInfo',
            ),
            Text(
              '-- Taken Snapshots --\n${_formatSnapshots()}',
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
