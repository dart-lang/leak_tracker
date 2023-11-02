import 'package:leak_tracker/leak_tracker.dart';

void main(List<String> arguments) {
  LeakTracking.start();
  // ignore: avoid_print
  print('Hello, world!');
  LeakTracking.stop();
}
