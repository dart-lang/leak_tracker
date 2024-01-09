#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `analyze` for all code in the repo.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sh $TOOL_DIR/pub_get.sh

cd $TOOL_DIR/../examples/autosnapshotting
flutter analyze  --fatal-infos

cd $TOOL_DIR/../examples/leak_tracking
flutter analyze --fatal-infos

cd $TOOL_DIR/../pkgs/leak_tracker
dart analyze --fatal-infos

cd $TOOL_DIR/../pkgs/leak_tracker_flutter_testing
flutter analyze --fatal-infos

cd $TOOL_DIR/../pkgs/leak_tracker_testing
dart analyze --fatal-infos

cd $TOOL_DIR/../pkgs/memory_usage
dart analyze --fatal-infos
