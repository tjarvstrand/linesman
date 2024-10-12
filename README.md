[![pub package](https://img.shields.io/pub/v/linesman.svg?label=linesman&color=blue)](https://pub.dev/packages/linesman)
[![pub package](https://img.shields.io/pub/v/linesman_lint.svg?label=linesman_lint&color=blue)](https://pub.dev/packages/linesman_lint)
![building](https://github.com/tjarvstrand/linesman/workflows/linesman/badge.svg)

# Linesman

Linesman helps you enforce boundaries between different parts of your codebase by providing a way to
define and validate valid imports between modules, components, or any other logical units in your
Dart application.

## Install

Linesman is currently only available as a (`custom_lint`)[https://pub.dev/packages/custom_lint]
plugin. To use it, follow the instructions for that package, then add you rules to
`analysis_options.yaml`, e.g:

```yaml
custom_lint:
  rules:
    - linesman_lint:
      allowByDefault: false
      rules:
        - type: allow
          source: test.dart
          target: some_file.dart
        - type: deny
          source: test.dart
          target: some_other_file.dart
```

## Usage

The allowed imports in your code are defined by a list of rules set in your config in
`analysis_options.yaml`.

There are two types of rules:
- `allow`: Allows imports of files that match the target glob into files that match the source glob.
- `deny`: Denies imports of files that match the target glob into files that match the source glob.

The ordering of rules matters. Subsequent rules will override previous ones if they match the same
source and target.

Matching is performed using the [glob](https://pub.dev/packages/glob) package, which means you can
use wildcards and other glob patterns to specify your source and target files.

If no rules are defined, or if a particular rule is not defined, the default behavior is defined by
the `allowByDefault` setting, which itself defaults to `true`.

## Contributing

PRs accepted.

## License

Apache 2.0 © Thomas Järvstrand
