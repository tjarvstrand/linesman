import 'package:linesman/src/rule.dart';
import 'package:test/test.dart';

void main() {
  group('Rule', () {
    test('Compare equal', () {
      expect(Deny(source: 'foo', target: 'bar'), equals(Deny(source: 'foo', target: 'bar')));
      expect(Allow(source: 'foo', target: 'bar'), equals(Allow(source: 'foo', target: 'bar')));
      expect(Allow(source: 'foo', target: 'bar'), isNot(equals(Deny(source: 'foo', target: 'bar'))));
    });
  });
}
