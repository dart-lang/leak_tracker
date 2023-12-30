#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `publish` for leak tracking packages in the repo in right order.

# Fast fail the script on failures.
set -ex

cd pkgs/leak_tracker
dart pub publish
cd -

cd pkgs/leak_tracker_testing
dart pub publish
cd -

cd pkgs/leak_tracker_flutter_testing
flutter pub publish
cd -
