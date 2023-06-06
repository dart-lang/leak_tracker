#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fast fail the script on failures.
set -ex

cd examples/autosnapshotting
flutter pub get
flutter analyze  --fatal-infos
cd -

cd examples/minimal_flutter
flutter pub get
flutter analyze --fatal-infos
cd -

cd pkgs/leak_tracker
dart pub get
dart analyze --fatal-infos
cd -

cd pkgs/leak_tracker_flutter_test
flutter pub get
flutter analyze --fatal-infos
cd -

cd pkgs/leak_tracker_testing
flutter pub get
dart analyze --fatal-infos
cd -
