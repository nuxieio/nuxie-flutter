import 'package:flutter_test/flutter_test.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';

void main() {
  test('instance access before initialize throws', () {
    expect(
      () => Nuxie.instance,
      throwsA(isA<NuxieException>()),
    );
  });
}
