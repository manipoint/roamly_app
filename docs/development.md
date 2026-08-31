# Development

## Requirements

- Flutter stable with a Dart SDK compatible with `^3.12.1`;
- Xcode for iOS development;
- Android Studio or an Android SDK for Android development; and
- a supported IDE with Dart and Flutter extensions.

## Install dependencies

Run dependency resolution from the repository root:

```bash
flutter pub get
```

The workspace uses one root `pubspec.lock`. Do not commit lockfiles inside
`apps` or `packages`.

## List workspace packages

```bash
dart pub workspace list
```

## Format and analyze

```bash
dart format .
flutter analyze
```

## Run application tests

```bash
cd apps/roamly_app
flutter test
```

## Run the application

Run Flutter commands from the executable application directory:

```bash
cd apps/roamly_app
flutter run
```

Environment-specific backend URLs will be supplied by application bootstrap
configuration. Do not commit credentials or hardcode API keys in Dart source.

## Add a workspace package

Create a package without resolving dependencies inside the package directory:

```bash
dart create --template=package --no-pub packages/roamly_core
```

Every workspace member must include:

```yaml
publish_to: none
resolution: workspace
```

Once the first package exists, the root workspace may include all package
manifests:

```yaml
workspace:
  - apps/roamly_app
  - packages/*
```

Then resolve once from the repository root:

```bash
flutter pub get
```

## Dependency policy

- Add dependencies to the package that imports them.
- Avoid adding a package to the root only to make it globally available.
- Keep domain packages free of Flutter and infrastructure dependencies.
- Review major upgrades before changing version constraints.
- Do not update dependencies only because `pub get` reports newer incompatible
  versions.

## Quality gate

Before committing, run:

```bash
dart format .
flutter analyze

cd apps/roamly_app
flutter test
```

All commands must pass before a commit is created.
