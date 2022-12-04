// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Name of extension to integrate the leak tracker with DevDools.
const String memoryLeakTrackingExtensionName = 'ext.dart.memoryLeakTracking';

/// Version of protocol, executed by the application.
const String appLeakTrackerProtocolVersion = '1';

enum Channel {
  requestToApp,
  eventFromApp,
  responseFromApp,
}
