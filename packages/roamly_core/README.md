# Roamly Core

`roamly_core` contains small, framework-independent primitives shared by
Roamly packages.

## Responsibilities

- Pure Dart APIs with no Flutter dependency.
- Typed application failures.
- Typed success and failure results.
- Shared validation primitives when more than one feature needs them.

## Getting started

This private package is resolved through the Roamly Pub Workspace. Run
`flutter pub get` from the repository root.

## Usage

Workspace packages add `roamly_core` as a dependency and import only its public
library:

```dart
import 'package:roamly_core/roamly_core.dart';
```

## Boundaries

Keep this package deliberately small. Flutter widgets, Riverpod providers, Dio
clients, feature DTOs, and feature-specific business rules belong in their own
packages.

See the workspace [architecture documentation](../../docs/architecture.md) for
dependency rules.
