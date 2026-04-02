import 'package:equatable/equatable.dart';
import 'package:glob/glob.dart';

abstract class Rule with EquatableMixin {
  Rule({required this.sources, required this.targets, required this.type});

  factory Rule.fromJson(Map<dynamic, dynamic> json, {Map<String, List<String>> groups = const {}}) {
    List<String> getValues(String key) {
      final value = json[key];
      List<String> raw;
      if (value is String) {
        if (value.isEmpty) {
          throw ArgumentError('$key must be non-empty');
        }
        raw = [value];
      } else if (value is List) {
        raw = value.cast<String>();
        if (raw.isEmpty) {
          throw ArgumentError('$key must be non-empty');
        }
        for (final s in raw) {
          if (s.isEmpty) {
            throw ArgumentError('$key entries must be non-empty');
          }
        }
      } else {
        throw ArgumentError('$key must be a string or list of strings');
      }
      final expanded = <String>[];
      for (final s in raw) {
        if (s.startsWith(r'$')) {
          final groupName = s.substring(1);
          final group = groups[groupName];
          if (group == null) {
            throw ArgumentError('Unknown group: $groupName');
          }
          expanded.addAll(group);
        } else {
          expanded.add(s);
        }
      }
      return expanded;
    }

    String getType() {
      final value = json['type'] as String?;
      if (value == null || value.isEmpty) {
        throw ArgumentError('type must be non-empty');
      }
      return value;
    }

    final message = json['message'] as String?;
    return switch (getType()) {
      'allow' => Allow(sources: getValues('source'), targets: getValues('target')),
      'deny' => Deny(sources: getValues('source'), targets: getValues('target'), message: message),
      final t => throw ArgumentError('Unknown rule type: $t'),
    };
  }

  final String? type;

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
  Allow({required super.sources, required super.targets}) : super(type: 'allow');

  @override
  bool? isAllowed(String sourcePackage, String source, String target) =>
      matches(sourcePackage, source, target) ? true : null;

  @override
  List<Object?> get props => [sources, targets];
}

class Deny extends Rule {
  Deny({required super.sources, required super.targets, this.message}) : super(type: 'disallow');

  final String? message;

  @override
  bool? isAllowed(String sourcePackage, String source, String target) =>
      matches(sourcePackage, source, target) ? false : null;

  @override
  List<Object?> get props => [sources, targets];

  @override
  String toString() => 'Deny(sources: $sources, targets: $targets, message: $message)';
}
