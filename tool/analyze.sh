#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fast fail the script on failures.
set -ex

sh ./tool/pub_get.sh

cd examples/autosnapshotting
flutter analyze  --fatal-infos
cd -

cd examples/minimal_flutter
flutter analyze --fatal-infos
cd -

cd pkgs/leak_tracker
dart analyze --fatal-infos
cd -

cd pkgs/leak_tracker_flutter
flutter analyze --fatal-infos
cd -

cd pkgs/leak_tracker_testing
dart analyze --fatal-infos
cd -
