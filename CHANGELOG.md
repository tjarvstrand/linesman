# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
 - Added test_project to .pubignore
 - Untracked pubspec.lock

### Changed
 - Use shared release script

## [0.2.0] - 2026-04-03

### Changed
 - Migrated from `custom_lint` to the native `analysis_server_plugin` architecture (requires Dart 3.10+).
 - Merged `linesman` and `linesman_lint` into a single `linesman` package.
 - Configuration is now read from a dedicated `linesman.yaml` file instead of `analysis_options.yaml`.
 - `source` and `target` in rules now accept a list of patterns in addition to a single string.

### Added
 - Named groups: define reusable sets of file patterns under `groups` and reference them in rules with a `$` prefix.
 - Custom `message` field on deny rules, shown in the diagnostic output.
 - Layer enforcement via the `layers` key: define an ordered architecture where imports can only go downward, with optional peer isolation.
 - `transitiveLayers` option (default `true`): when `false`, layers can only import from the layer directly below them.

## 0.1.0+1 - 2025-06-30

### Fixed
 - Added homepage to pubspec.yaml.

## 0.1.0 - 2025-06-30

### Added
- Initial version.
