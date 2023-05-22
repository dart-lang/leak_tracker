// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Code needs to match API from VmService.

library vm_service_wrapper;

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import '_json_to_service_cache.dart';
import '_vm_service_private_extensions.dart';

class VmServiceWrapper implements VmService {
  VmServiceWrapper(
    this._vmService,
    this._connectedUri, {
    this.trackFutures = false,
  });

  VmServiceWrapper.fromNewVmService(
    Stream<dynamic> /*String|List<int>*/ inStream,
    void Function(String message) writeMessage,
    this._connectedUri, {
    Log? log,
    DisposeHandler? disposeHandler,
    this.trackFutures = false,
  }) {
    _vmService = VmService(
      inStream,
      writeMessage,
      log: log,
      disposeHandler: disposeHandler,
    );
    //unawaited(_initSupportedProtocols());
  }

  late final VmService _vmService;

  Uri get connectedUri => _connectedUri;
  final Uri _connectedUri;

  final bool trackFutures;
  final Map<String, Future<Success>> _activeStreams = {};

  final Set<TrackedFuture<Object>> activeFutures = {};
  Completer<bool> _allFuturesCompleter = Completer<bool>()
    // Mark the future as completed by default so if we don't track any
    // futures but someone tries to wait on [allFuturesCompleted] they don't
    // hang. The first tracked future will replace this with a new completer.
    ..complete(true);

  Future<void> get allFuturesCompleted => _allFuturesCompleter.future;

  // A local cache of "fake" service objects. Used to convert JSON objects to
  // VM service response formats to be used with APIs that require them.
  final fakeServiceCache = JsonToServiceCache();

  /// Executes `callback` for each isolate, and waiting for all callbacks to
  /// finish before completing.
  Future<void> forEachIsolate(
    Future<void> Function(IsolateRef) callback,
  ) async {
    final vm = await _vmService.getVM();
    final futures = <Future>[];
    for (final isolate in vm.isolates ?? []) {
      futures.add(callback(isolate));
    }
    await Future.wait(futures);
  }

  @override
  Future get onDone => _vmService.onDone;

  @override
  Future<void> dispose() => _vmService.dispose();

  @override
  Future<FlagList> getFlagList() =>
      _trackFuture('getFlagList', _vmService.getFlagList());

  @override
  Future<InstanceSet> getInstances(
    String isolateId,
    String objectId,
    int limit, {
    bool? includeSubclasses,
    bool? includeImplementers,
  }) async {
    return _trackFuture(
      'getInstances',
      _vmService.getInstances(
        isolateId,
        objectId,
        limit,
        includeSubclasses: includeSubclasses,
        includeImplementers: includeImplementers,
      ),
    );
  }

  @override
  Future<ScriptList> getScripts(String isolateId) {
    return _trackFuture('getScripts', _vmService.getScripts(isolateId));
  }

  @override
  Future<ClassList> getClassList(String isolateId) {
    return _trackFuture('getClassList', _vmService.getClassList(isolateId));
  }

  @override
  Future<SourceReport> getSourceReport(
    String isolateId,
    List<String> reports, {
    String? scriptId,
    int? tokenPos,
    int? endTokenPos,
    bool? forceCompile,
    bool? reportLines,
    List<String>? libraryFilters,
  }) async {
    return _trackFuture(
      'getSourceReport',
      _vmService.getSourceReport(
        isolateId,
        reports,
        scriptId: scriptId,
        tokenPos: tokenPos,
        endTokenPos: endTokenPos,
        forceCompile: forceCompile,
        reportLines: reportLines,
        libraryFilters: libraryFilters,
      ),
    );
  }

  @override
  Future<Stack> getStack(String isolateId, {int? limit}) async {
    return _trackFuture(
      'getStack',
      _vmService.getStack(isolateId, limit: limit),
    );
  }

  @override
  Future<VM> getVM() => _trackFuture('getVM', _vmService.getVM());

  @override
  Future<Timeline> getVMTimeline({
    int? timeOriginMicros,
    int? timeExtentMicros,
  }) async {
    return _trackFuture(
      'getVMTimeline',
      _vmService.getVMTimeline(
        timeOriginMicros: timeOriginMicros,
        timeExtentMicros: timeExtentMicros,
      ),
    );
  }

  @override
  Future<TimelineFlags> getVMTimelineFlags() {
    return _trackFuture('getVMTimelineFlags', _vmService.getVMTimelineFlags());
  }

  @override
  Future<Timestamp> getVMTimelineMicros() async {
    return _trackFuture(
      'getVMTimelineMicros',
      _vmService.getVMTimelineMicros(),
    );
  }

  @override
  Future<Version> getVersion() async {
    return _trackFuture('getVersion', _vmService.getVersion());
  }

  @override
  Future<MemoryUsage> getMemoryUsage(String isolateId) =>
      _trackFuture('getMemoryUsage', _vmService.getMemoryUsage(isolateId));

  @override
  Future<Response> invoke(
    String isolateId,
    String targetId,
    String selector,
    List<String> argumentIds, {
    bool? disableBreakpoints,
  }) {
    return _trackFuture(
      'invoke $selector',
      _vmService.invoke(
        isolateId,
        targetId,
        selector,
        argumentIds,
        disableBreakpoints: disableBreakpoints,
      ),
    );
  }

  @override
  Future<Success> requestHeapSnapshot(String isolateId) {
    return _trackFuture(
      'requestHeapSnapshot',
      _vmService.requestHeapSnapshot(isolateId),
    );
  }

  Future<HeapSnapshotGraph> getHeapSnapshotGraph(IsolateRef isolateRef) async {
    return await HeapSnapshotGraph.getSnapshot(_vmService, isolateRef);
  }

  @override
  Future<Success> kill(String isolateId) {
    return _trackFuture('kill', _vmService.kill(isolateId));
  }

  @override
  Stream<Event> get onDebugEvent => _vmService.onDebugEvent;

  @override
  Stream<Event> get onProfilerEvent => _vmService.onProfilerEvent;

  @override
  Stream<Event> onEvent(String streamName) => _vmService.onEvent(streamName);

  @override
  Stream<Event> get onExtensionEvent => _vmService.onExtensionEvent;

  @override
  Stream<Event> get onGCEvent => _vmService.onGCEvent;

  @override
  Stream<Event> get onIsolateEvent => _vmService.onIsolateEvent;

  @override
  Stream<Event> get onLoggingEvent => _vmService.onLoggingEvent;

  @override
  Stream<Event> get onTimelineEvent => _vmService.onTimelineEvent;

  @override
  Stream<String> get onReceive => _vmService.onReceive;

  @override
  Stream<String> get onSend => _vmService.onSend;

  @override
  Stream<Event> get onServiceEvent => _vmService.onServiceEvent;

  @override
  Stream<Event> get onStderrEvent => _vmService.onStderrEvent;

  @override
  Stream<Event> get onStdoutEvent => _vmService.onStdoutEvent;

  @override
  Stream<Event> get onVMEvent => _vmService.onVMEvent;

  @override
  Stream<Event> get onHeapSnapshotEvent => _vmService.onHeapSnapshotEvent;

  @override
  Future<Success> pause(String isolateId) {
    return _trackFuture('pause', _vmService.pause(isolateId));
  }

  @override
  Future<Success> registerService(String service, String alias) async {
    return _trackFuture(
      'registerService $service',
      _vmService.registerService(service, alias),
    );
  }

  @override
  void registerServiceCallback(String service, ServiceCallback cb) {
    return _vmService.registerServiceCallback(service, cb);
  }

  @override
  Future<ReloadReport> reloadSources(
    String isolateId, {
    bool? force,
    bool? pause,
    String? rootLibUri,
    String? packagesUri,
  }) {
    return _trackFuture(
      'reloadSources',
      _vmService.reloadSources(
        isolateId,
        force: force,
        pause: pause,
        rootLibUri: rootLibUri,
        packagesUri: packagesUri,
      ),
    );
  }

  @override
  Future<Success> removeBreakpoint(String isolateId, String breakpointId) {
    return _trackFuture(
      'removeBreakpoint',
      _vmService.removeBreakpoint(isolateId, breakpointId),
    );
  }

  @override
  Future<Success> resume(String isolateId, {String? step, int? frameIndex}) {
    return _trackFuture(
      'resume',
      _vmService.resume(isolateId, step: step, frameIndex: frameIndex),
    );
  }

  @override
  Future<Success> setIsolatePauseMode(
    String isolateId, {
    /*ExceptionPauseMode*/ String? exceptionPauseMode,
    bool? shouldPauseOnExit,
  }) {
    return _trackFuture(
      'setIsolatePauseMode',
      _vmService.setIsolatePauseMode(
        isolateId,
        exceptionPauseMode: exceptionPauseMode,
        shouldPauseOnExit: shouldPauseOnExit,
      ),
    );
  }

  @override
  Future<Response> setFlag(String name, String value) {
    return _trackFuture('setFlag', _vmService.setFlag(name, value));
  }

  @override
  Future<Success> setLibraryDebuggable(
    String isolateId,
    String libraryId,
    bool isDebuggable,
  ) {
    return _trackFuture(
      'setLibraryDebuggable',
      _vmService.setLibraryDebuggable(isolateId, libraryId, isDebuggable),
    );
  }

  @override
  Future<Success> setName(String isolateId, String name) {
    return _trackFuture('setName', _vmService.setName(isolateId, name));
  }

  @override
  Future<Success> setVMName(String name) {
    return _trackFuture('setVMName', _vmService.setVMName(name));
  }

  @override
  Future<Success> setVMTimelineFlags(List<String> recordedStreams) async {
    return _trackFuture(
      'setVMTimelineFlags',
      _vmService.setVMTimelineFlags(recordedStreams),
    );
  }

  @override
  Future<Success> streamCancel(String streamId) {
    _activeStreams.remove(streamId);
    return _trackFuture('streamCancel', _vmService.streamCancel(streamId));
  }

  // We tweaked this method so that we do not try to listen to the same stream
  // twice. This was causing an issue with the test environment and this change
  // should not affect the run environment.
  @override
  Future<Success> streamListen(String streamId) {
    if (!_activeStreams.containsKey(streamId)) {
      final Future<Success> future =
          _trackFuture('streamListen', _vmService.streamListen(streamId));
      _activeStreams[streamId] = future;
      return future;
    } else {
      return _activeStreams[streamId]!.then((value) => value);
    }
  }

  @override
  Future<RetainingPath> getRetainingPath(
    String isolateId,
    String targetId,
    int limit,
  ) =>
      _trackFuture(
        'getRetainingPath',
        _vmService.getRetainingPath(isolateId, targetId, limit),
      );

  // TODO(bkonyi): move this method to
  // https://github.com/dart-lang/sdk/blob/master/pkg/vm_service/lib/src/dart_io_extensions.dart
  Future<bool> isHttpProfilingAvailable(String isolateId) async {
    final Isolate isolate = await getIsolate(isolateId);
    return (isolate.extensionRPCs ?? []).contains('ext.dart.io.getHttpProfile');
  }
  // Mark: end overrides for the [DartIOExtension].

  /// Testing only method to indicate that we don't really need to await all
  /// currently pending futures.
  ///
  /// If you use this method be sure to indicate why you believe all pending
  /// futures are safe to ignore. Currently the theory is this method should be
  /// used after a hot restart to avoid bugs where we have zombie futures lying
  /// around causing tests to flake.
  void doNotWaitForPendingFuturesBeforeExit() {
    _allFuturesCompleter = Completer<bool>();
    _allFuturesCompleter.complete(true);
    activeFutures.clear();
  }

  /// Retrieves the full string value of a [stringRef].
  ///
  /// The string value stored with the [stringRef] is returned unless the value
  /// is truncated, in which an extra getObject call is issued to return the
  /// value. If the [stringRef] has expired so the full string is unavailable,
  /// [onUnavailable] is called to return how the truncated value should be
  /// displayed. If [onUnavailable] is not specified, an exception is thrown
  /// if the full value cannot be retrieved.
  Future<String?> retrieveFullStringValue(
    String isolateId,
    InstanceRef stringRef, {
    String Function(String? truncatedValue)? onUnavailable,
  }) async {
    if (stringRef.valueAsStringIsTruncated != true) {
      return stringRef.valueAsString;
    }

    final result = await getObject(
      isolateId,
      stringRef.id!,
      offset: 0,
      count: stringRef.length,
    );
    if (result is Instance) {
      return result.valueAsString;
    } else if (onUnavailable != null) {
      return onUnavailable(stringRef.valueAsString);
    } else {
      throw Exception(
        'The full string for "{stringRef.valueAsString}..." is unavailable',
      );
    }
  }

  final _vmServiceCalls = <String>[];

  /// If logging is enabled, wraps a future with logs at its start and finish.
  ///
  /// All logs from this run will have matching unique ids, so that they can
  /// be associated together in the logs.
  Future<T> _maybeLogWrappedFuture<T>(
    String name,
    Future<T> future,
  ) async {
    return future;
    // // If the logger is not accepting FINE logs, then we won't be logging any
    // // messages. So just return the [future] as-is.
    // if (!_log.isLoggable(Level.FINE)) return future;

    // final logId = ++_logIdCounter;
    // try {
    //   _log.fine('[$logId]-trackFuture($name,...): Started');
    //   final result = await future;
    //   _log.fine('[$logId]-trackFuture($name,...): Succeeded');
    //   return result;
    // } catch (error) {
    //   _log.severe(
    //     '[$logId]-trackFuture($name,...): Failed',
    //     error,
    //   );
    //   rethrow;
    // }
  }

  Future<T> _trackFuture<T>(String name, Future<T> future) {
    final localFuture = _maybeLogWrappedFuture<T>(name, future);

    if (!trackFutures) {
      return localFuture;
    }

    _vmServiceCalls.add(name);

    final trackedFuture = TrackedFuture(name, localFuture as Future<Object>);
    if (_allFuturesCompleter.isCompleted) {
      _allFuturesCompleter = Completer<bool>();
    }
    activeFutures.add(trackedFuture);

    void futureComplete() {
      activeFutures.remove(trackedFuture);
      if (activeFutures.isEmpty && !_allFuturesCompleter.isCompleted) {
        _allFuturesCompleter.complete(true);
      }
    }

    localFuture.then(
      (value) => futureComplete(),
      onError: (error) => futureComplete(),
    );
    return localFuture;
  }

  /// Adds support for private VM RPCs that can only be used when VM developer
  /// mode is enabled. Not for use outside of VM developer pages.
  /// Allows callers to invoke extension methods for private RPCs. This should
  /// only be set by [PreferencesController.toggleVmDeveloperMode] or tests.
  static bool enablePrivateRpcs = false;

  Future<T?> _privateRpcInvoke<T>(
    String method, {
    required T? Function(Map<String, dynamic>?) parser,
    String? isolateId,
    Map<String, dynamic>? args,
  }) async {
    if (!enablePrivateRpcs) {
      throw StateError('Attempted to invoke private RPC');
    }
    final result = await _trackFuture(
      method,
      callMethod(
        '_$method',
        isolateId: isolateId,
        args: args,
      ),
    );
    return parser(result.json);
  }

  /// Forces the VM to perform a full garbage collection.
  Future<Success?> collectAllGarbage() => _privateRpcInvoke(
        'collectAllGarbage',
        parser: Success.parse,
      );

  Future<InstanceRef?> getReachableSize(String isolateId, String targetId) =>
      _privateRpcInvoke(
        'getReachableSize',
        isolateId: isolateId,
        args: {
          'targetId': targetId,
        },
        parser: InstanceRef.parse,
      );

  Future<InstanceRef?> getRetainedSize(String isolateId, String targetId) =>
      _privateRpcInvoke(
        'getRetainedSize',
        isolateId: isolateId,
        args: {
          'targetId': targetId,
        },
        parser: InstanceRef.parse,
      );

  Future<ObjectStore?> getObjectStore(String isolateId) => _privateRpcInvoke(
        'getObjectStore',
        isolateId: isolateId,
        parser: ObjectStore.parse,
      );

  /// Prevent DevTools from blocking Dart SDK rolls if changes in
  /// package:vm_service are unimplemented in DevTools.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class TrackedFuture<T> {
  TrackedFuture(this.name, this.future);

  final String name;
  final Future<T> future;
}
