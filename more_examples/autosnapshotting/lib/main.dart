// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leak_tracker/leak_tracker.dart';

void main(List<String> args, {String? snapshotDirectory}) {
  runApp(MyApp(snapshotDirectory: snapshotDirectory));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.snapshotDirectory});

  final String? snapshotDirectory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autosnapshotting Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Autosnapshotting Demo',
        snapshotDirectory: snapshotDirectory,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.snapshotDirectory});

  final String title;
  final String? snapshotDirectory;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

final _allocations = <List<DateTime>>[];

class MyHomePageState extends State<MyHomePage> {
  final _formatter = NumberFormat('#,###,000');
  final snapshots = <SnapshotInfo>[];
  int lastRss = 0;
  late AutoSnapshottingConfig config;

  void _allocateMemory() {
    setState(() {
      _allocations.add(List.generate(1000000, (_) => DateTime.now()));
      lastRss = ProcessInfo.currentRss;
    });
  }

  @override
  void initState() {
    super.initState();

    config = AutoSnapshottingConfig(
      onSnapshot: _handleSnapshot,
      thresholdMb: 400,
      increaseMb: 100,
      directorySizeLimitMb: 500,
      directory: widget.snapshotDirectory ?? 'dart_snapshots',
      minDelayBetweenSnapshots: const Duration(seconds: 5),
    );

    trackMemoryUsage(config: config);
  }

  void _handleSnapshot(SnapshotInfo record) {
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
              '-- Auto-Snapshotting Configuration --\n$config',
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
