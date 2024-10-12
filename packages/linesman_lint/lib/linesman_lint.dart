// ignore_for_file: avoid_print

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:linesman/linesman.dart';
import 'package:path/path.dart' as p;

PluginBase createPlugin() => _Linter();

extension UriComponentPathExt on Uri {
  String get componentPath => p.basename(p.relative(path, from: pathSegments[0]));
}

class _Linter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    final options = configs.rules['linesman_lint'];
    return [LinesmanLint._(configs.verbose, options == null ? const Config() : Config.fromJson(options.json))];
  }
}

class LinesmanLint extends DartLintRule {
  const LinesmanLint._(this._verbose, this._config)
    : super(code: const LintCode(name: _code, errorSeverity: _severity, problemMessage: 'Disallowed import'));

  final bool _verbose;
  final Config _config;

  static const _code = 'linesman_lint';
  static const _severity = ErrorSeverity.WARNING;

  @override
  Future<void> run(CustomLintResolver resolver, ErrorReporter reporter, CustomLintContext context) async {
    final unit = await resolver.getResolvedUnitResult();
    final sourcePath = unit.uri.componentPath;

    context.registry.addImportDirective((import) {
      final uri = import.libraryImport?.uri;
      if (uri is! DirectiveUriWithLibrary) {
        return;
      }
      final targetPath = uri.source.uri.componentPath;
      final (:allowed, :matchedRules) = check(_config, sourcePath, targetPath);

      if (_verbose || _config.verbose) {
        print('${allowed ? 'Allowed' : 'Disallowed'} import $targetPath:');
        if (matchedRules.isEmpty) {
          print(' * No rules matched');
        } else {
          for (final rule in matchedRules) {
            print(' * ${rule.description}');
          }
        }
      }

      if (!allowed) {
        reporter.atNode(import, code);
      }
    });
  }
}
