import 'package:linesman/src/rule.dart';
import 'package:test/test.dart';

void main() {
  group('Rule', () {
    test('Compare equal', () {
      expect(
        Deny(sources: ['foo'], targets: ['bar']),
        equals(Deny(sources: ['foo'], targets: ['bar'])),
      );
      expect(
        Allow(sources: ['foo'], targets: ['bar']),
        equals(Allow(sources: ['foo'], targets: ['bar'])),
      );
      expect(
        Allow(sources: ['foo'], targets: ['bar']),
        isNot(equals(Deny(sources: ['foo'], targets: ['bar']))),
      );
    });
  });
}
