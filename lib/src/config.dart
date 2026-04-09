import 'package:linesman/src/rule.dart';

class Config {
  const Config({this.groups = const {}, this.rules = const [], this.allowByDefault = true, this.verbose = false});

  factory Config.fromJson(Map<dynamic, dynamic> json) {
    final groupsJson = (json['groups'] as Map? ?? {}).cast<String, dynamic>();
    final groups = {
      for (final MapEntry(:key, :value) in groupsJson.entries)
        key: switch (value) {
          final List<dynamic> v => v.cast<String>(),
          final String v => [v],
          _ => throw ArgumentError('Group "$key" must be a string or list of strings'),
        },
    };
    final allowByDefault = json['allowByDefault'] as bool? ?? true;
    final allowTransitiveLayerAccess = json['allowTransitiveLayerAccess'] as bool? ?? false;
    final layerRules = _parseLayerRules(
      json['layers'] as List? ?? [],
      groups,
      allowByDefault,
      allowTransitiveLayerAccess,
    );
    final explicitRules =
        (json['rules'] as List<dynamic>?)?.map((e) => Rule.fromJson(e as Map, groups: groups)).toList() ?? [];
    return Config(
      verbose: json['verbose'] as bool? ?? false,
      allowByDefault: allowByDefault,
      groups: groups,
      rules: [...layerRules, ...explicitRules],
    );
  }

  static List<Rule> _parseLayerRules(
    List<dynamic> layers,
    Map<String, List<String>> groups,
    bool allowByDefault,
    bool allowTransitiveLayerAccess,
  ) {
    final parsedLayers = [
      for (final layer in layers)
        if (layer is String)
          [_expandPatterns(layer, groups)]
        else if (layer is List)
          layer.map((e) => _expandPatterns(e as String, groups)).toList()
        else
          throw ArgumentError('Layer entry must be a string or list of strings'),
    ];

    return [
      for (final (i, layer) in parsedLayers.indexed) ...[
        // Deny peer imports within the same layer.
        for (final peerA in layer)
          for (final peerB in layer)
            if (peerA != peerB) Deny(sources: peerA, targets: peerB, message: 'Layer violation'),
        // Cross-layer rules: deny upward, allow/deny downward based on adjacency.
        if (i < parsedLayers.length - 1)
          for (final (j, lowerLayer) in parsedLayers.sublist(i + 1).indexed)
            for (final lowerPeer in lowerLayer)
              for (final upperPeer in layer) ...[
                // Always deny upward imports.
                if (allowByDefault) Deny(sources: lowerPeer, targets: upperPeer, message: 'Layer violation'),
                // Downward: allow if transitive, or if adjacent (j == 0).
                if (allowTransitiveLayerAccess || j == 0) ...[
                  if (!allowByDefault) Allow(sources: upperPeer, targets: lowerPeer),
                ] else ...[
                  if (allowByDefault) Deny(sources: upperPeer, targets: lowerPeer, message: 'Layer violation'),
                ],
              ],
      ],
    ];
  }

  static List<String> _expandPatterns(String value, Map<String, List<String>> groups) {
    if (!value.startsWith(r'$')) {
      return [value];
    }
    final groupName = value.substring(1);
    final group = groups[groupName];
    return group ?? (throw ArgumentError('Unknown group: $groupName'));
  }

  final bool allowByDefault;
  final bool verbose;
  final Map<String, List<String>> groups;
  final List<Rule> rules;

  /// Merges [other] on top of this config.
  ///
  /// Groups from both configs are combined (other's groups override on key
  /// collision). Rules from this config come first, then other's rules
  /// (so other's rules take precedence). Other's scalar settings
  /// (allowByDefault, verbose) win.
  Config merge(Config other) => Config(
    allowByDefault: other.allowByDefault,
    verbose: other.verbose,
    groups: {...groups, ...other.groups},
    rules: [...rules, ...other.rules],
  );

  @override
  String toString() => 'Config(allowByDefault: $allowByDefault, rules: $rules)';
}
