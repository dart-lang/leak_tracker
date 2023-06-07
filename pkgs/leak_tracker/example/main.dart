import 'package:leak_tracker/leak_tracker.dart';

void main(List<String> arguments) {
  enableLeakTracking();
  // ignore: avoid_print
  print('Hello, world!');
  disableLeakTracking();
}
