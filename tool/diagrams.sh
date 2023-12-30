#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Regenerates dependency diagrams for all packages in the repo.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=`dirname "$0"`

sh $TOOL_DIR/pub_get.sh

cd $TOOL_DIR/../pkgs/leak_tracker
dart run layerlens
cd -

cd $TOOL_DIR/../pkgs/leak_tracker_testing
dart run layerlens
cd -

cd $TOOL_DIR/../pkgs/leak_tracker_flutter_testing
dart run layerlens
cd -

cd $TOOL_DIR/../pkgs/memory_usage
dart run layerlens
cd -
