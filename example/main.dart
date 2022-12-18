import 'package:leak_tracker/leak_tracker.dart';

void main(List<String> arguments) {
  enableLeakTracking();
  print('Hello, world!');
  disableLeakTracking();
}
