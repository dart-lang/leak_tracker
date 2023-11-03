#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Regenerates dependency disgrams for all packages in the repo.

# Fast fail the script on failures.
set -ex

sh ./tool/pub_get.sh

cd pkgs/leak_tracker
dart run layerlens
cd -

cd pkgs/leak_tracker_testing
dart run layerlens
cd -

cd pkgs/memory_usage
dart run layerlens
cd -
