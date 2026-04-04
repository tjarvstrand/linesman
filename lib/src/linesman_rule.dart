import 'dart:io' as io;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:linesman/linesman.dart';
import 'package:linesman/src/config.dart';
import 'package:linesman/src/rule.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class LinesmanRule extends AnalysisRule {
  LinesmanRule() : super(name: 'linesman', description: 'Enforce import boundary rules.');

  static const LintCode code = LintCode('linesman', 'Disallowed import{0}');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final packageRoot = context.package?.root.path;
    if (packageRoot == null) {
      return;
    }

    final config = _loadConfig(packageRoot);
    final visitor = _Visitor(this, context, config);
    registry.addImportDirective(this, visitor);
  }

  static Config _loadConfig(String packageRoot) {
    final workspaceRoot = _isWorkspaceMember(packageRoot) ? _findWorkspaceRoot(packageRoot) : null;
    final workspaceConfig = workspaceRoot != null ? _loadConfigFile(workspaceRoot) : null;
    final packageConfig = _loadConfigFile(packageRoot);

    if (workspaceConfig != null && packageConfig != null) {
      return workspaceConfig.merge(packageConfig);
    }
    return packageConfig ?? workspaceConfig ?? const Config();
  }

  static Config? _loadConfigFile(String directory) {
    final file = io.File(p.join(directory, 'linesman.yaml'));
    if (!file.existsSync()) {
      return null;
    }
    return Config.fromJson(loadYaml(file.readAsStringSync()) as Map);
  }

  /// Returns whether the package at [packageRoot] is a workspace member
  /// (has `resolution: workspace` in its `pubspec.yaml`).
  static bool _isWorkspaceMember(String packageRoot) {
    final pubspec = io.File(p.join(packageRoot, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      return false;
    }
    final yaml = loadYaml(pubspec.readAsStringSync());
    return yaml is Map && yaml['resolution'] == 'workspace';
  }

  /// Walks up from [packageRoot] to find a pub workspace root.
  ///
  /// A workspace root is a directory containing a `pubspec.yaml` with a
  /// `workspace` key. Returns `null` if no workspace root is found.
  static String? _findWorkspaceRoot(String packageRoot) {
    final dir = p.dirname(packageRoot);
    if (dir == packageRoot) {
      return null;
    }
    final pubspec = io.File(p.join(dir, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final yaml = loadYaml(pubspec.readAsStringSync());
      if (yaml is Map && yaml.containsKey('workspace')) {
        return dir;
      }
    }
    return _findWorkspaceRoot(dir);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context, this.config);

  final LinesmanRule rule;
  final RuleContext context;
  final Config config;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.libraryImport?.uri;
    if (uri is! DirectiveUriWithLibrary) {
      return;
    }

    final currentUnit = context.currentUnit;
    if (currentUnit == null) {
      return;
    }

    final sourceUri = currentUnit.unit.declaredFragment?.source.uri;
    if (sourceUri == null) {
      return;
    }

    final sourcePackage = sourceUri.pathSegments[0];
    final sourcePath = sourceUri.path;
    final targetPath = uri.source.uri.path;

    final (:allowed, :matchedRules) = check(config, sourcePackage, sourcePath, targetPath);

    if (!allowed) {
      final lastDeny = matchedRules.whereType<Deny>().lastOrNull;
      final message = lastDeny?.message;
      rule.reportAtNode(node, arguments: [if (message != null) ': $message' else '']);
    }
  }
}
