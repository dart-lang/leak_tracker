// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Names for json fields.
class _JsonFields {
  static const String version = 'version';
}

class LeakTrackingStarted {
  LeakTrackingStarted(this.protocolVersion);
  factory LeakTrackingStarted.fromJson(Map<String, dynamic> json) =>
      LeakTrackingStarted(json[_JsonFields.version] as String);

  Map<String, dynamic> toJson() => {_JsonFields.version: protocolVersion};

  final String protocolVersion;
}

class RequestForLeakDetails {}

class LeakTrackingTurnedOffError {}

class UnexpectedRequestTypeError {
  UnexpectedRequestTypeError(Type type) : type = type.toString();

  final String type;
}

class UnexpectedError {
  UnexpectedError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
