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

    final configFile = io.File(p.join(packageRoot, 'linesman.yaml'));
    final config = configFile.existsSync()
        ? Config.fromJson(loadYaml(configFile.readAsStringSync()) as Map)
        : const Config();

    final visitor = _Visitor(this, context, config);
    registry.addImportDirective(this, visitor);
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
