// ignore_for_file: avoid_redundant_argument_values

import 'package:linesman/linesman.dart';
import 'package:linesman/src/config.dart' show Config;
import 'package:linesman/src/rule.dart';
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
          rules: [
            Deny(sources: ['bar'], targets: ['bar']),
          ],
          allowByDefault: true,
        );
        final result = check(config, 'package', 'foo', 'bar');
        expect(result.allowed, isTrue);
        expect(result.matchedRules, isEmpty);
      });
      test('returns false if no allow rules match and allowByDefault is false', () {
        final config = Config(
          rules: [
            Allow(sources: ['bar'], targets: ['bar']),
          ],
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

    group('groups', () {
      test('expands group reference in source', () {
        final rule = Rule.fromJson(
          {'type': 'deny', 'source': r'$mygroup', 'target': 'bar'},
          groups: {
            'mygroup': ['foo', 'baz'],
          },
        );
        expect(rule.sources, equals(['foo', 'baz']));
        expect(rule.targets, equals(['bar']));
      });
      test('expands group reference in target', () {
        final rule = Rule.fromJson(
          {'type': 'deny', 'source': 'foo', 'target': r'$mygroup'},
          groups: {
            'mygroup': ['bar', 'baz'],
          },
        );
        expect(rule.sources, equals(['foo']));
        expect(rule.targets, equals(['bar', 'baz']));
      });
      test('mixes group references and inline patterns', () {
        final rule = Rule.fromJson(
          {
            'type': 'deny',
            'source': [r'$mygroup', 'inline'],
            'target': 'bar',
          },
          groups: {
            'mygroup': ['foo', 'baz'],
          },
        );
        expect(rule.sources, equals(['foo', 'baz', 'inline']));
      });
      test('throws on unknown group reference', () {
        expect(() => Rule.fromJson({'type': 'deny', 'source': r'$unknown', 'target': 'bar'}), throwsArgumentError);
      });
      test('Config.fromJson parses groups and passes them to rules', () {
        final config = Config.fromJson({
          'groups': {
            'internal': ['lib/src/internal/**', 'lib/src/private/**'],
          },
          'rules': [
            {'type': 'deny', 'source': '**', 'target': r'$internal'},
          ],
        });
        expect(config.groups, {
          'internal': ['lib/src/internal/**', 'lib/src/private/**'],
        });
        expect(config.rules.first.targets, equals(['lib/src/internal/**', 'lib/src/private/**']));
      });
    });

    group('layers', () {
      test('allows downward imports', () {
        final config = Config.fromJson({
          'layers': ['lib/ui/**', 'lib/domain/**', 'lib/data/**'],
        });
        // ui -> domain: allowed
        expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/domain/model.dart').allowed, isTrue);
        // ui -> data: allowed
        expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/data/repo.dart').allowed, isTrue);
        // domain -> data: allowed
        expect(check(config, 'p', 'p/lib/domain/model.dart', 'p/lib/data/repo.dart').allowed, isTrue);
      });
      test('denies upward imports', () {
        final config = Config.fromJson({
          'layers': ['lib/ui/**', 'lib/domain/**', 'lib/data/**'],
        });
        // data -> ui: denied
        expect(check(config, 'p', 'p/lib/data/repo.dart', 'p/lib/ui/page.dart').allowed, isFalse);
        // data -> domain: denied
        expect(check(config, 'p', 'p/lib/data/repo.dart', 'p/lib/domain/model.dart').allowed, isFalse);
        // domain -> ui: denied
        expect(check(config, 'p', 'p/lib/domain/model.dart', 'p/lib/ui/page.dart').allowed, isFalse);
      });
      test('denies peer imports within the same layer', () {
        final config = Config.fromJson({
          'layers': [
            [r'$http', r'$db'],
            'lib/domain/**',
          ],
          'groups': {
            'http': ['lib/http/**'],
            'db': ['lib/db/**'],
          },
        });
        // http -> db: denied
        expect(check(config, 'p', 'p/lib/http/client.dart', 'p/lib/db/repo.dart').allowed, isFalse);
        // db -> http: denied
        expect(check(config, 'p', 'p/lib/db/repo.dart', 'p/lib/http/client.dart').allowed, isFalse);
      });
      test('allows imports within the same non-peer group', () {
        final config = Config.fromJson({
          'layers': ['lib/ui/**', 'lib/domain/**'],
        });
        // ui -> ui: allowed (same group, not peers)
        expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/ui/widget.dart').allowed, isTrue);
      });
      test('peers can import downward', () {
        final config = Config.fromJson({
          'layers': [
            [r'$http', r'$db'],
            'lib/domain/**',
          ],
          'groups': {
            'http': ['lib/http/**'],
            'db': ['lib/db/**'],
          },
        });
        // http -> domain: allowed
        expect(check(config, 'p', 'p/lib/http/client.dart', 'p/lib/domain/model.dart').allowed, isTrue);
        // db -> domain: allowed
        expect(check(config, 'p', 'p/lib/db/repo.dart', 'p/lib/domain/model.dart').allowed, isTrue);
      });
      test('explicit rules override layer rules', () {
        final config = Config.fromJson({
          'layers': ['lib/ui/**', 'lib/domain/**'],
          'rules': [
            {'type': 'allow', 'source': 'lib/domain/**', 'target': 'lib/ui/**'},
          ],
        });
        // domain -> ui: normally denied by layers, but allowed by explicit rule
        expect(check(config, 'p', 'p/lib/domain/model.dart', 'p/lib/ui/page.dart').allowed, isTrue);
      });
      test('uses groups in layer entries', () {
        final config = Config.fromJson({
          'groups': {
            'ui': ['lib/ui/**'],
            'domain': ['lib/domain/**'],
          },
          'layers': [r'$ui', r'$domain'],
        });
        // domain -> ui: denied
        expect(check(config, 'p', 'p/lib/domain/model.dart', 'p/lib/ui/page.dart').allowed, isFalse);
        // ui -> domain: allowed
        expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/domain/model.dart').allowed, isTrue);
      });
      group('transitiveLayers', () {
        test('defaults to true, allowing skipping layers', () {
          final config = Config.fromJson({
            'layers': ['lib/ui/**', 'lib/domain/**', 'lib/data/**'],
          });
          // ui -> data: allowed (skips domain)
          expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/data/repo.dart').allowed, isTrue);
        });
        test('when false, denies non-adjacent downward imports', () {
          final config = Config.fromJson({
            'transitiveLayers': false,
            'layers': ['lib/ui/**', 'lib/domain/**', 'lib/data/**'],
          });
          // ui -> domain: allowed (adjacent)
          expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/domain/model.dart').allowed, isTrue);
          // ui -> data: denied (non-adjacent)
          expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/data/repo.dart').allowed, isFalse);
          // domain -> data: allowed (adjacent)
          expect(check(config, 'p', 'p/lib/domain/model.dart', 'p/lib/data/repo.dart').allowed, isTrue);
        });
        test('when false, still denies upward imports', () {
          final config = Config.fromJson({
            'transitiveLayers': false,
            'layers': ['lib/ui/**', 'lib/domain/**', 'lib/data/**'],
          });
          // data -> ui: denied
          expect(check(config, 'p', 'p/lib/data/repo.dart', 'p/lib/ui/page.dart').allowed, isFalse);
          // data -> domain: denied
          expect(check(config, 'p', 'p/lib/data/repo.dart', 'p/lib/domain/model.dart').allowed, isFalse);
        });
        test('when false, still denies peer imports', () {
          final config = Config.fromJson({
            'transitiveLayers': false,
            'layers': [
              [r'$http', r'$db'],
              'lib/domain/**',
            ],
            'groups': {
              'http': ['lib/http/**'],
              'db': ['lib/db/**'],
            },
          });
          expect(check(config, 'p', 'p/lib/http/client.dart', 'p/lib/db/repo.dart').allowed, isFalse);
          expect(check(config, 'p', 'p/lib/db/repo.dart', 'p/lib/http/client.dart').allowed, isFalse);
        });
        test('when false with allowByDefault false, only allows adjacent', () {
          final config = Config.fromJson({
            'allowByDefault': false,
            'transitiveLayers': false,
            'layers': ['lib/ui/**', 'lib/domain/**', 'lib/data/**'],
          });
          // ui -> domain: allowed (adjacent)
          expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/domain/model.dart').allowed, isTrue);
          // ui -> data: denied (non-adjacent)
          expect(check(config, 'p', 'p/lib/ui/page.dart', 'p/lib/data/repo.dart').allowed, isFalse);
          // data -> ui: denied (upward)
          expect(check(config, 'p', 'p/lib/data/repo.dart', 'p/lib/ui/page.dart').allowed, isFalse);
        });
      });
    });

    group('merge', () {
      test('other rules come after base rules', () {
        final baseRule = Deny(sources: ['a'], targets: ['b']);
        final otherRule = Allow(sources: ['a'], targets: ['b']);
        const base = Config(rules: []);
        final merged = Config(rules: [baseRule]).merge(Config(rules: [otherRule]));
        expect(merged.rules, equals([baseRule, otherRule]));
        // Other's allow overrides base's deny (later rules win)
        expect(check(merged, 'p', 'p/a', 'p/b').allowed, isTrue);
      });
      test('other allowByDefault wins', () {
        const base = Config(allowByDefault: true);
        final merged = base.merge(const Config(allowByDefault: false));
        expect(merged.allowByDefault, isFalse);
      });
      test('groups are combined with other taking precedence on collision', () {
        final base = Config(groups: {
          'shared': ['a'],
          'base_only': ['b'],
        });
        final other = Config(groups: {
          'shared': ['c'],
          'other_only': ['d'],
        });
        final merged = base.merge(other);
        expect(merged.groups, {
          'shared': ['c'],
          'base_only': ['b'],
          'other_only': ['d'],
        });
      });
    });
  });
}
