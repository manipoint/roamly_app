# Roamly

Roamly is a Flutter client for an AI-assisted travel planning platform. It
connects to the Roamly backend for authentication, trip management, flight and
hotel search, places, weather, currency conversion, and itinerary generation.

## Project status

The backend is deployed to Google Cloud Run. The Flutter application is in its
initial architecture and workspace setup phase.

The first mobile release will use email and password authentication. Social
login and email verification are intentionally deferred.

## Repository structure

```text
roamly/
├── apps/
│   └── roamly_app/
├── packages/
├── docs/
├── analysis_options.yaml
└── pubspec.yaml
```

- `apps/roamly_app` contains the executable Flutter application and platform
  projects.
- `packages` contains reusable core, design-system, networking, and feature
  packages as they are introduced.
- `docs` contains architecture and development documentation.

## Architecture

Roamly follows feature-oriented Clean Architecture with SOLID dependency
boundaries. Riverpod manages state and dependency composition, Dio handles HTTP
transport, and `go_router` provides Router-based navigation.

See [Architecture](docs/architecture.md) for package boundaries and dependency
rules.

## Development

See the [Development guide](docs/development.md) for workspace setup, analysis,
testing, and package creation commands.

## Backend

The backend is maintained and deployed independently from this Flutter
workspace. Client configuration must supply the backend URL per environment;
feature code must not hardcode service URLs or credentials.
