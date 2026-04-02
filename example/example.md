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

# Define reusable named groups of file patterns
groups:
  internal:
    - package:my_app/src/internal/**
    - package:my_app/src/private/**
  features:
    - feature_a/**
    - feature_b/**

rules:
  # Deny all files from importing internal code
  - type: deny
    source: "**"
    target: $internal

  # Except internal code can import other internal code
  - type: allow
    source: $internal
    target: $internal

  # Groups and inline patterns can be mixed
  - type: deny
    source:
      - $features
      - utils/**
    target: $internal
```
