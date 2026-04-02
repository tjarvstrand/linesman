# Linesman Example

## 1. Add linesman as a dev dependency

```yaml
# pubspec.yaml
dev_dependencies:
  linesman: ^0.1.0
```

## 2. Enable the plugin

```yaml
# analysis_options.yaml
plugins:
  linesman: ^0.1.0
```

## 3. Configure rules

```yaml
# linesman.yaml
rules:
  # Deny all files from importing internal code
  - type: deny
    source: "**"
    target: package:my_app/src/internal/**

  # Except internal code can import other internal code
  - type: allow
    source: package:my_app/src/internal/**
    target: package:my_app/src/internal/**

  # Multiple sources/targets can be specified as lists
  - type: deny
    source:
      - lib/feature_a/**
      - lib/feature_b/**
    target:
      - package:my_app/src/secret/**
      - package:my_app/src/private/**
```
