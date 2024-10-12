// ignore_for_file: avoid_redundant_argument_values

import 'package:linesman/linesman.dart';
import 'package:test/test.dart';

void main() {
  group('Config', () {
    group('canReference', () {
      test('returns true for same target and source even if allowByDefault is false', () {
        const config = Config(rules: [], allowByDefault: false);
        final result = check(config, 'foo', 'foo');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, isEmpty);
      });
      test('returns true when rules are empty and allowByDefault is true', () {
        const config = Config(rules: [], allowByDefault: true);
        final result = check(config, 'foo', 'bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, isEmpty);
      });
      test('returns false when rules are empty and allowByDefault is false', () {
        const config = Config(rules: [], allowByDefault: false);
        final result = check(config, 'foo', 'bar');
        expect(result.allowed, isFalse);
        expect(result.matchedRules, isEmpty);
      });
      test('returns true if no disallow rules match and allowByDefault is true', () {
        final config = Config(rules: [Deny(source: 'bar', target: 'bar')], allowByDefault: true);
        final result = check(config, 'foo', 'bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, isEmpty);
      });
      test('returns false if no allow rules match and allowByDefault is false', () {
        final config = Config(rules: [Allow(source: 'bar', target: 'bar')], allowByDefault: false);
        final result = check(config, 'foo', 'bar');
        expect(result.allowed, isFalse);
        expect(result.matchedRules, isEmpty);
      });
      test('returns false if a disallow rule matches and allowByDefault is true', () {
        final rule = Deny(source: 'foo', target: 'bar');
        final config = Config(rules: [rule], allowByDefault: true);
        final result = check(config, 'foo', 'bar');
        expect(result.allowed, isFalse);
        expect(result.matchedRules, equals([rule]));
      });
      test('returns true if an allow rule matches and allowByDefault is false', () {
        final rule = Allow(source: 'foo', target: 'bar');
        final config = Config(rules: [rule], allowByDefault: false);
        final result = check(config, 'foo', 'bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, equals([rule]));
      });
      test('subsequent rules override previous ones', () {
        final rule1 = Deny(source: 'foo', target: 'bar');
        final rule2 = Allow(source: 'foo', target: 'bar');
        final config = Config(rules: [rule1, rule2], allowByDefault: true);
        final result = check(config, 'foo', 'bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, equals([rule1, rule2]));
      });
    });
  });
}
