import 'package:equatable/equatable.dart';
import 'package:glob/glob.dart';

abstract class Rule with EquatableMixin {
  Rule({required this.sources, required this.targets, required this.type, String? description})
    : _description = description;

  factory Rule.fromJson(Map<dynamic, dynamic> json) {
    List<String> getValues(String key) {
      final value = json[key];
      if (value is String) {
        if (value.isEmpty) {
          throw ArgumentError('$key must be non-empty');
        }
        return [value];
      }
      if (value is List) {
        final strings = value.cast<String>();
        if (strings.isEmpty) {
          throw ArgumentError('$key must be non-empty');
        }
        for (final s in strings) {
          if (s.isEmpty) {
            throw ArgumentError('$key entries must be non-empty');
          }
        }
        return strings;
      }
      throw ArgumentError('$key must be a string or list of strings');
    }

    String getType() {
      final value = json['type'] as String?;
      if (value == null || value.isEmpty) {
        throw ArgumentError('type must be non-empty');
      }
      return value;
    }

    final description = json['description'] as String?;
    return switch (getType()) {
      'allow' => Allow(sources: getValues('source'), targets: getValues('target'), description: description),
      'deny' => Deny(sources: getValues('source'), targets: getValues('target'), description: description),
      final t => throw ArgumentError('Unknown rule type: $t'),
    };
  }

  final String? type;

  final String? _description;
  String get description => _description ?? '$runtimeType: $sources -> $targets';

  final List<String> sources;
  final List<String> targets;

  static String _normalizePath(String path, String packageName) {
    if (path.startsWith('package:')) {
      return path.substring(8);
    }
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return '$packageName/$relativePath';
  }

  bool matches(String sourcePackage, String source, String target) =>
      sources.any((s) => Glob(_normalizePath(s, sourcePackage)).matches(source)) &&
      targets.any((t) => Glob(_normalizePath(t, sourcePackage)).matches(target));

  bool? isAllowed(String sourcePackage, String source, String target);
}

class Allow extends Rule {
  Allow({required super.sources, required super.targets, super.description}) : super(type: 'allow');

  @override
  bool? isAllowed(String sourcePackage, String source, String target) =>
      matches(sourcePackage, source, target) ? true : null;

  @override
  List<Object?> get props => [sources, targets];
}

class Deny extends Rule {
  Deny({required super.sources, required super.targets, super.description}) : super(type: 'disallow');

  @override
  bool? isAllowed(String sourcePackage, String source, String target) =>
      matches(sourcePackage, source, target) ? false : null;

  @override
  List<Object?> get props => [sources, targets];

  @override
  String toString() => 'Disallow(sources: $sources, targets: $targets, description: $description)';
}
