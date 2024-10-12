import 'package:linesman/src/rule.dart';

class Config {
  const Config({this.rules = const [], this.allowByDefault = true, this.verbose = false});
  factory Config.fromJson(Map<dynamic, dynamic> json) {
    final rules = (json['rules'] as List<dynamic>?)?.map((e) => Rule.fromJson(e as Map)).toList() ?? [];
    return Config(
      verbose: json['verbose'] as bool? ?? false,
      allowByDefault: json['allowByDefault'] as bool? ?? true,
      rules: rules,
    );
  }

  final bool allowByDefault;
  final bool verbose;
  final List<Rule> rules;

  @override
  String toString() => 'Config(allowByDefault: $allowByDefault, rules: $rules)';
}
