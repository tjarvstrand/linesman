import 'package:equatable/equatable.dart';
import 'package:glob/glob.dart';

abstract class Rule with EquatableMixin {
  Rule({required this.source, required this.target, required this.type, String? description})
    : _description = description;

  factory Rule.fromJson(Map<dynamic, dynamic> json) {
    String getValue(String key) {
      final value = json[key] as String?;
      if (value == null) {
        throw ArgumentError('$key must be non-null');
      }
      if (value.isEmpty) {
        throw ArgumentError('$key must be non-empty');
      }
      return value;
    }

    final description = json['description'] as String?;
    return switch (getValue('type')) {
      'allow' => Allow(source: getValue('source'), target: getValue('target'), description: description),
      'deny' => Deny(source: getValue('source'), target: getValue('target'), description: description),
      final t => throw ArgumentError('Unknown rule type: $t'),
    };
  }

  final String? type;

  final String? _description;
  String get description => _description ?? '$runtimeType: $source -> $target';

  final String source;
  final String target;

  static String _normalizePath(String path, String packageName) {
    if (path.startsWith('package:')) {
      return path.substring(8);
    }
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return '$packageName/$relativePath';
  }

  bool matches(String sourcePackage, String source, String target) =>
      Glob(_normalizePath(this.source, sourcePackage)).matches(source) &&
      Glob(_normalizePath(this.target, sourcePackage)).matches(target);

  bool? isAllowed(String sourcePackage, String source, String target);
}

class Allow extends Rule {
  Allow({required super.source, required super.target, super.description}) : super(type: 'allow');

  @override
  bool? isAllowed(String sourcePackage, String source, String target) =>
      matches(sourcePackage, source, target) ? true : null;

  @override
  List<Object?> get props => [source, target];
}

class Deny extends Rule {
  Deny({required super.source, required super.target, super.description}) : super(type: 'disallow');

  @override
  bool? isAllowed(String sourcePackage, String source, String target) =>
      matches(sourcePackage, source, target) ? false : null;

  @override
  List<Object?> get props => [source, target];

  @override
  String toString() => 'Disallow(source: $source, target: $target, description: $description)';
}
