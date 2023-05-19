import 'package:leak_tracker/src/leak_tracking/retaining_path/_retaining_path.dart';
import 'package:test/test.dart';

class MyClass {
  MyClass();
}

void main() {
  test('$MyClass instance can be found.', () async {
    final instance = MyClass();

    final path = await obtainRetainingPath(MyClass, identityHashCode(instance));
    expect(path.elements, isNotEmpty);
  });
}
