#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `pub get` for all code in the repo.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=`dirname "$0"`

cd $TOOL_DIR/../examples/autosnapshotting
flutter pub get
cd -

cd $TOOL_DIR/../examples/leak_tracking
flutter pub get
cd -

cd $TOOL_DIR/../pkgs/leak_tracker
dart pub get
cd -

cd $TOOL_DIR/../pkgs/leak_tracker_flutter_testing
flutter pub get
cd -

cd $TOOL_DIR/../pkgs/leak_tracker_testing
flutter pub get
cd -

cd $TOOL_DIR/../pkgs/leak_tracker_web_tests
flutter pub get
cd -

cd $TOOL_DIR/../pkgs/memory_usage
dart pub get
cd -
