[![pub package](https://img.shields.io/pub/v/linesman.svg?label=linesman&color=blue)](https://pub.dev/packages/linesman)
![main](https://github.com/tjarvstrand/linesman/actions/workflows/test.yaml/badge.svg?branch=main)


# Linesman

Linesman helps you enforce boundaries between different parts of your codebase by providing a way to
define and validate imports between modules, components, or any other logical units in your
Dart application.

## Requirements

Dart 3.10 or later.

## Install

Add linesman as a dev dependency:

```yaml
# pubspec.yaml
dev_dependencies:
  linesman: ^0.1.0
```

Enable the plugin in `analysis_options.yaml`:

```yaml
# analysis_options.yaml
plugins:
  linesman: ^0.1.0
```

## Configuration

Rules are defined in a `linesman.yaml` file in your package root:

```yaml
# linesman.yaml
allowByDefault: false
rules:
  - type: allow
    source: test.dart
    target: some_file.dart
  - type: deny
    source: test.dart
    target: some_other_file.dart
    message: Use some_file.dart instead
  - type: deny
    source: test.dart
    target: package:some_package/some_other_file.dart
```

## Usage

The allowed imports in your code are defined by the list of rules in `linesman.yaml`.

There are two types of rules:
- `allow`: Allows imports of files that match the target glob into files that match the source glob.
- `deny`: Denies imports of files that match the target glob into files that match the source glob.
  Supports an optional `message` field shown in the diagnostic output.

`source` and `target` accept either a single glob pattern or a list of patterns:

```yaml
rules:
  - type: deny
    source:
      - feature_a/**
      - feature_b/**
    target: package:my_app/src/internal/**
```

Matching is performed using the [glob](https://pub.dev/packages/glob) package, which means you can
use wildcards and other glob patterns to specify your source and target files.

Globs can be specified with a `package:<package_name>/` prefix to match files in a specific package.
If no such prefix is present, the glob will only match files in the current package.

The ordering of rules matters. Subsequent rules will override previous ones that match the same
source and target.

If no rules are defined, or if a particular source is not matched by any rule, the default behavior
is defined by the `allowByDefault` setting, which itself defaults to `true`.

### Groups

You can define named groups of patterns under the `groups` key and reference them in rules with a
`$` prefix. Groups and inline patterns can be mixed in the same list:

```yaml
groups:
  internal:
    - src/internal/**
    - src/private/**
  features:
    - feature_a/**
    - feature_b/**

rules:
  - type: deny
    source: $features
    target: $internal
  - type: deny
    source:
      - $features
      - utils/**
    target: $internal
```

### Layers

The `layers` key enforces a layered architecture. Each entry is a group reference or glob pattern, or a list of the
same. Imports can only go downward — lower layers cannot import from higher layers:

```yaml
groups:
  ui:
    - ui/**
  domain:
    - domain/**
  data:
    - data/**

layers:
  - $application
  - [$domain, util/**]
  - [$http_client, $db, $messaging]
```

By default, upper layers can import from any lower layer. Set `transitiveLayers: false` to restrict
imports to only the immediately adjacent layer below:

```yaml
transitiveLayers: false
layers:
  - $ui
  - $domain
  - $data
```

With this setting, `ui` can import from `domain` but not from `data`.

Using layers will trigger automatic generation of an initial rule set that is applied before explicit `rules`. This
makes it easy to create overrides where exceptions are needed.

### Pub Workspaces

In a [pub workspace](https://dart.dev/tools/pub/pubspec#workspace), you can place a `linesman.yaml`
at the workspace root to define rules that apply across all packages. Linesman detects the workspace
root by walking up from the package root and looking for a `pubspec.yaml` with a `workspace` key.

If both a workspace-level and a package-level `linesman.yaml` exist, they are merged: workspace
rules are evaluated first, then package rules. This means package-level rules can override workspace
rules. Groups are also merged, with package-level groups taking precedence on name collisions.

## Contributing

PRs accepted.

## License

Apache 2.0 © Thomas Järvstrand
