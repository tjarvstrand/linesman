import 'package:linesman_lint/linesman_lint.dart';
import 'package:test/test.dart';

void main() {
  group('UriComponentPathExt', () {
    test('componentPath', () {
      expect(Uri.parse('package:test/test.dart').componentPath, 'test.dart');
    });
  });
}
