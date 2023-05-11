// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leak_tracker/leak_tracker.dart';

late String _snapshotDirectory;

extension SizeConversion on int {
  static const _bytesInMB = 1024 * 1024;
  int mbToBytes() => this * _bytesInMB;
  int bytesToMB() => (this / _bytesInMB).round();
}

void main(List<String> args, {String? snapshotDirectory}) {
  _snapshotDirectory = snapshotDirectory ?? 'dart_snapshots';
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
      home: const MyHomePage(
        title: 'Autosnapshotting Demo',
      ),
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
  final snapshots = <SnapshotEvent>[];
  final usageEvents = <MemoryUsageEvent>[];
  int lastRss = 0;
  late UsageTrackingConfig config;

  void _allocateMemory() {
    setState(() {
      _allocations.add(List.generate(1000000, (_) => DateTime.now()));
      lastRss = ProcessInfo.currentRss;
    });
  }

  @override
  void initState() {
    super.initState();

    config = UsageTrackingConfig(
      autoSnapshottingConfig: AutoSnapshottingConfig(
        onSnapshot: _handleSnapshotEvent,
        thresholdMb: 400,
        increaseMb: 100,
        directorySizeLimitMb: 500,
        directory: _snapshotDirectory,
        minDelayBetweenSnapshots: const Duration(seconds: 5),
      ),
      usageEventsConfig: UsageEventsConfig(
        _handleUsageEvent,
        deltaMb: 100,
      ),
    );

    trackMemoryUsage(config);
  }

  void _handleSnapshotEvent(SnapshotEvent event) {
    setState(() {
      snapshots.add(event);
    });
  }

  void _handleUsageEvent(MemoryUsageEvent event) {
    setState(() {
      usageEvents.add(event);
    });
  }

  String _formatSize(int bytes) {
    return '${_formatter.format(bytes)} (${_formatter.format(bytes.bytesToMB())} MB)';
  }

  String _formatSnapshots() {
    return snapshots.map((snapshot) {
      final time = DateFormat('HH:mm:ss').format(snapshot.timestamp);
      return '$time : ${snapshot.fileName}';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    const space = SizedBox(height: 20);
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
            space,
            Text(
              '-- Configuration --\n$config',
            ),
            space,
            Text(
              '-- Usage Events (MB) --\n${usageEvents.map((e) => _formatter.format(e.rss.bytesToMB())).join('; ')}',
            ),
            space,
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
