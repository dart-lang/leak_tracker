// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

late String twoControllers;

/// Verification for the tests happens in flutter_test_config.dart.
void main() {
  testWidgetsWithLeakTracking(
      twoControllers = 'Two not disposed controllers results in two leaks.',
      (tester) async {
    // ignore: unused_local_variable
    final TextEditingController controller = TextEditingController();
    print('!!!! ${identityHashCode(controller)}');
    // ignore: unused_local_variable
    final FocusNode focusNode = FocusNode(debugLabel: 'Test Node');

    await tester.pumpWidget(
      Material(
        child: MaterialApp(
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (BuildContext context, Animation<double> input,
                  Animation<double> out) {
                return Focus(
                  child: TextField(
                    autofocus: true,
                    focusNode: focusNode,
                    controller: controller,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isTrue);
  });
}
