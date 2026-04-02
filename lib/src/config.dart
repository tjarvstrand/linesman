import 'package:linesman/src/rule.dart';

class Config {
  const Config({this.groups = const {}, this.rules = const [], this.allowByDefault = true, this.verbose = false});
  factory Config.fromJson(Map<dynamic, dynamic> json) {
    final groupsJson = json['groups'] as Map?;
    final groups = <String, List<String>>{};
    if (groupsJson != null) {
      for (final entry in groupsJson.entries) {
        final name = entry.key as String;
        final value = entry.value;
        if (value is List) {
          groups[name] = value.cast<String>();
        } else if (value is String) {
          groups[name] = [value];
        } else {
          throw ArgumentError('Group "$name" must be a string or list of strings');
        }
      }
    }
    final rules =
        (json['rules'] as List<dynamic>?)?.map((e) => Rule.fromJson(e as Map, groups: groups)).toList() ?? [];
    return Config(
      verbose: json['verbose'] as bool? ?? false,
      allowByDefault: json['allowByDefault'] as bool? ?? true,
      groups: groups,
      rules: rules,
    );
  }

  final bool allowByDefault;
  final bool verbose;
  final Map<String, List<String>> groups;
  final List<Rule> rules;

  @override
  String toString() => 'Config(allowByDefault: $allowByDefault, rules: $rules)';
}
