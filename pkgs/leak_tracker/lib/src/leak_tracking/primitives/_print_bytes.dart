// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String? prettyPrintBytes(
  num? bytes, {
  int kbFractionDigits = 0,
  int mbFractionDigits = 1,
  int gbFractionDigits = 1,
  bool includeUnit = false,
  num roundingPoint = 1.0,
  int maxBytes = 52,
}) {
  if (bytes == null) {
    return null;
  }
  // TODO(peterdjlee): Generalize to handle different kbFractionDigits.
  // Ensure a small number of bytes does not print as 0 KB.
  // If bytes >= maxBytes and kbFractionDigits == 1,
  // it will start rounding to 0.1 KB.
  if (bytes.abs() < maxBytes && kbFractionDigits == 1) {
    var output = bytes.toString();
    if (includeUnit) {
      output += ' B';
    }
    return output;
  }
  final sizeInKB = bytes.abs() / 1024.0;
  final sizeInMB = sizeInKB / 1024.0;
  final sizeInGB = sizeInMB / 1024.0;

  if (sizeInGB >= roundingPoint) {
    return printGB(
      bytes,
      fractionDigits: gbFractionDigits,
      includeUnit: includeUnit,
    );
  } else if (sizeInMB >= roundingPoint) {
    return printMB(
      bytes,
      fractionDigits: mbFractionDigits,
      includeUnit: includeUnit,
    );
  } else {
    return printKB(
      bytes,
      fractionDigits: kbFractionDigits,
      includeUnit: includeUnit,
    );
  }
}

String printKB(num bytes, {int fractionDigits = 0, bool includeUnit = false}) {
  // We add ((1024/2)-1) to the value before formatting so that a non-zero byte
  // value doesn't round down to 0. If showing decimal points, let it round
  // normally.
  // TODO(peterdjlee): Round up to the respective digit when fractionDigits > 0.
  final processedBytes = fractionDigits == 0 ? bytes + 511 : bytes;
  var output = (processedBytes / 1024.0).toStringAsFixed(fractionDigits);
  if (includeUnit) {
    output += ' KB';
  }
  return output;
}

String printMB(num bytes, {int fractionDigits = 1, bool includeUnit = false}) {
  var output = (bytes / (1024 * 1024.0)).toStringAsFixed(fractionDigits);
  if (includeUnit) {
    output += ' MB';
  }
  return output;
}

String printGB(num bytes, {int fractionDigits = 1, bool includeUnit = false}) {
  var output =
      (bytes / (1024 * 1024.0 * 1024.0)).toStringAsFixed(fractionDigits);
  if (includeUnit) {
    output += ' GB';
  }
  return output;
}
