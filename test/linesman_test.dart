// ignore_for_file: avoid_redundant_argument_values

import 'package:linesman/linesman.dart';
import 'package:test/test.dart';

void main() {
  group('Config', () {
    group('canReference', () {
      test('returns true for same target and source even if allowByDefault is false', () {
        const config = Config(rules: [], allowByDefault: false);
        final result = check(config, 'package', 'foo', 'foo');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, isEmpty);
      });
      test('returns true when rules are empty and allowByDefault is true', () {
        const config = Config(rules: [], allowByDefault: true);
        final result = check(config, 'package', 'foo', 'bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, isEmpty);
      });
      test('returns false when rules are empty and allowByDefault is false', () {
        const config = Config(rules: [], allowByDefault: false);
        final result = check(config, 'package', 'foo', 'bar');
        expect(result.allowed, isFalse);
        expect(result.matchedRules, isEmpty);
      });
      test('returns true if no disallow rules match and allowByDefault is true', () {
        final config = Config(
          rules: [Deny(sources: ['bar'], targets: ['bar'])],
          allowByDefault: true,
        );
        final result = check(config, 'package', 'foo', 'bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, isEmpty);
      });
      test('returns false if no allow rules match and allowByDefault is false', () {
        final config = Config(
          rules: [Allow(sources: ['bar'], targets: ['bar'])],
          allowByDefault: false,
        );
        final result = check(config, 'package', 'foo', 'bar');
        expect(result.allowed, isFalse);
        expect(result.matchedRules, isEmpty);
      });
      test('returns false if a disallow rule matches and allowByDefault is true', () {
        final rule = Deny(sources: ['foo'], targets: ['bar']);
        final config = Config(rules: [rule], allowByDefault: true);
        final result = check(config, 'package', 'package/foo', 'package/bar');
        expect(result.allowed, isFalse);
        expect(result.matchedRules, equals([rule]));
      });
      test('returns true if an allow rule matches and allowByDefault is false', () {
        final rule = Allow(sources: ['foo'], targets: ['bar']);
        final config = Config(rules: [rule], allowByDefault: false);
        final result = check(config, 'package', 'package/foo', 'package/bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, equals([rule]));
      });
      test('subsequent rules override previous ones', () {
        final rule1 = Deny(sources: ['foo'], targets: ['bar']);
        final rule2 = Allow(sources: ['foo'], targets: ['bar']);
        final config = Config(rules: [rule1, rule2], allowByDefault: true);
        final result = check(config, 'package', 'package/foo', 'package/bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, equals([rule1, rule2]));
      });
      test('matches any source in the list', () {
        final rule = Deny(sources: ['foo', 'baz'], targets: ['bar']);
        final config = Config(rules: [rule], allowByDefault: true);
        expect(check(config, 'p', 'p/foo', 'p/bar').allowed, isFalse);
        expect(check(config, 'p', 'p/baz', 'p/bar').allowed, isFalse);
        expect(check(config, 'p', 'p/other', 'p/bar').allowed, isTrue);
      });
      test('matches any target in the list', () {
        final rule = Deny(sources: ['foo'], targets: ['bar', 'baz']);
        final config = Config(rules: [rule], allowByDefault: true);
        expect(check(config, 'p', 'p/foo', 'p/bar').allowed, isFalse);
        expect(check(config, 'p', 'p/foo', 'p/baz').allowed, isFalse);
        expect(check(config, 'p', 'p/foo', 'p/other').allowed, isTrue);
      });
    });

    group('fromJson', () {
      test('parses single source and target as strings', () {
        final rule = Rule.fromJson({'type': 'deny', 'source': 'foo', 'target': 'bar'});
        expect(rule.sources, equals(['foo']));
        expect(rule.targets, equals(['bar']));
      });
      test('parses source and target as lists', () {
        final rule = Rule.fromJson({
          'type': 'deny',
          'source': ['foo', 'baz'],
          'target': ['bar', 'qux'],
        });
        expect(rule.sources, equals(['foo', 'baz']));
        expect(rule.targets, equals(['bar', 'qux']));
      });
    });
  });
}
