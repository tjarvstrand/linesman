import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:linesman/src/linesman_rule.dart';

final plugin = LinesmanPlugin();

class LinesmanPlugin extends Plugin {
  @override
  String get name => 'linesman';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(LinesmanRule());
  }
}
