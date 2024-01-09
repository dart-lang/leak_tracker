#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `publish` for leak tracking packages in the repo in right order.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$( cd -- "$( dirname -- "$0" )" &> /dev/null && pwd )

cd $TOOL_DIR/../pkgs/leak_tracker
dart pub publish
cd -

cd $TOOL_DIR/../pkgs/leak_tracker_testing
dart pub publish
cd -

cd $TOOL_DIR/../pkgs/leak_tracker_flutter_testing
flutter pub publish
cd -
