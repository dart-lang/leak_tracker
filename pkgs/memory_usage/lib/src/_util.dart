// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extension SizeConversion on int {
  int get mbToBytes => this * 1024 * 1024;
}
