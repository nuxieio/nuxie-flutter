import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';
import 'package:test/test.dart';

void main() {
  test('platform interface starts with unsupported implementation', () {
    expect(
      () => NuxieFlutterPlatform.instance.getDistinctId(),
      throwsUnimplementedError,
    );
  });
}
