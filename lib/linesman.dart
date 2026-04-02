import 'package:linesman/src/config.dart';
import 'package:linesman/src/rule.dart';

export 'src/config.dart';
export 'src/rule.dart';

({bool allowed, List<Rule> matchedRules}) check(Config config, String sourcePackage, String source, String target) {
  var allowed = source == target || config.allowByDefault;
  final matchedRules = <Rule>[];
  for (final rule in config.rules) {
    final isAllowed = rule.isAllowed(sourcePackage, source, target);
    if (isAllowed != null) {
      allowed = isAllowed;
      matchedRules.add(rule);
    }
  }
  return (allowed: allowed, matchedRules: matchedRules);
}
