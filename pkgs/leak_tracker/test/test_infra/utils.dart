// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> loadPageHtmlContent(String url) async {
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();

  final completer = Completer<String>();
  final content = StringBuffer();
  response.transform(utf8.decoder).listen(
        content.write,
        onDone: () => completer.complete(content.toString()),
      );
  await completer.future;
  return content.toString();
}
