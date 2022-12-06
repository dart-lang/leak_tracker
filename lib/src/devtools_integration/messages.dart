// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Names for json fields.
class _JsonFields {
  static const String value = 'value';
  static const String error = 'error';
  static const String stackTrace = 'trace';
}

class LeakTrackingStarted {
  LeakTrackingStarted(this.protocolVersion);

  factory LeakTrackingStarted.fromJson(Map<String, dynamic> json) =>
      LeakTrackingStarted(json[_JsonFields.value] as String);

  Map<String, dynamic> toJson() => {_JsonFields.value: protocolVersion};

  final String protocolVersion;
}

class RequestForLeakDetails {}

class LeakTrackingTurnedOffError {}

class UnexpectedRequestTypeError {
  UnexpectedRequestTypeError(Type type) : type = type.toString();

  UnexpectedRequestTypeError.fromString(this.type);

  factory UnexpectedRequestTypeError.fromJson(Map<String, dynamic> json) =>
      UnexpectedRequestTypeError.fromString(json[_JsonFields.value] as String);

  Map<String, dynamic> toJson() => {_JsonFields.value: type};

  final String type;
}

class UnexpectedError {
  UnexpectedError(Object error, StackTrace stackTrace)
      : error = error.toString(),
        stackTrace = stackTrace.toString();

  UnexpectedError.fromStrings({required this.error, required this.stackTrace});

  factory UnexpectedError.fromJson(Map<String, dynamic> json) =>
      UnexpectedError.fromStrings(
        error: json[_JsonFields.error] as String,
        stackTrace: json[_JsonFields.stackTrace] as String,
      );

  Map<String, dynamic> toJson() => {
        _JsonFields.error: error,
        _JsonFields.stackTrace: stackTrace,
      };

  final String error;
  final String stackTrace;
}
