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
  - type: deny
    source: "**"
    target: package:my_app/src/internal/**
  - type: allow
    source: package:my_app/src/internal/**
    target: package:my_app/src/internal/**
```

This configuration denies all files from importing anything under `lib/src/internal/`,
except for files that are themselves inside `lib/src/internal/`.
