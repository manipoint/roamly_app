# Architecture

## Goals

Roamly's Flutter architecture is designed to provide:

- clear and testable dependency boundaries;
- independently maintainable feature modules;
- replaceable infrastructure adapters;
- reusable design foundations for future white-label applications;
- safe authentication and WebSocket session handling; and
- a structure that can grow without turning shared packages into dumping
  grounds.

The architecture follows SOLID principles and uses Clean Architecture where a
feature's complexity justifies explicit domain and data boundaries.

## Monorepo structure

The repository uses native Dart Pub Workspaces with one shared dependency
resolution and one root lockfile.

```text
roamly/
├── apps/
│   └── roamly_app/
└── packages/
    ├── roamly_core/
    ├── roamly_logging/
    ├── roamly_ui/
    ├── roamly_networking/
    ├── roamly_auth/
    ├── roamly_travel_assistant/
    └── roamly_trips/
```

`roamly_app`, `roamly_core`, `roamly_logging`, `roamly_ui`,
`roamly_networking`, and `roamly_auth` currently exist. The travel-assistant
and trips packages in this tree are planned. Additional packages are added
when their first real responsibility is implemented.

## Package responsibilities

### `roamly_app`

The executable application is the composition root. It owns:

- application bootstrap and environment selection;
- the root `ProviderScope` and dependency overrides;
- the complete navigation graph and authentication redirects;
- platform configuration; and
- assembly of feature packages.

### `roamly_core`

A framework-independent Dart package for genuinely shared primitives such as
typed results and application failures. It must not depend on Flutter, Dio,
Riverpod, navigation, or platform plugins.

### `roamly_logging`

A framework-independent structured logging package. It owns log levels,
records, sinks, severity filtering, and credential-field redaction. Features
receive loggers through dependency injection; they do not call `print` or bind
their business logic directly to a vendor logging SDK.

### `roamly_ui`

Owns brand tokens, typography, themes, spacing, and reusable components.
Application branding images remain in `apps/roamly_app/assets/branding`.
Feature widgets consume semantic theme values instead of hardcoded
colors or fonts. Brand configuration is injected at the application boundary
to support future white-label variants.

### `roamly_networking`

Owns the transport-neutral `ApiClient` contract, its `DioApiClient` adapter,
HTTP configuration, Dio construction, safe interceptors, request identifiers,
transport exceptions, and small authentication-token contracts. It does not
own feature endpoints, DTOs, response parsing, or business rules.

### `roamly_auth`

Owns registration, login, logout, session restoration, secure credential
storage, and authentication presentation. Social login and email verification
are outside the first release.

### `roamly_travel_assistant`

Will own WebSocket chat, travel events, structured clarification, reconnect
behavior, and assistant conversation presentation.

### `roamly_trips`

Will own trips, itinerary versions, itinerary items, and saved-plan screens.
Trips and itineraries remain together initially because their workflows and
domain lifecycle are closely related.

## Clean Architecture layers

Feature packages may contain these layers:

```text
feature/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── use_cases/
├── data/
│   ├── data_sources/
│   ├── dto/
│   └── repositories/
└── presentation/
    ├── controllers/
    ├── state/
    ├── views/
    └── widgets/
```

The domain layer is framework independent. Data implementations depend on
domain contracts, and presentation depends on domain behavior. Use-case
classes are introduced for meaningful business workflows, not as wrappers
around every repository method.

## Dependency rules

The intended dependency direction is:

```text
roamly_app
 ├── feature packages
 ├── roamly_ui
 ├── roamly_logging
 └── roamly_networking

feature packages ──> roamly_core
feature packages ──> roamly_networking
roamly_networking ─> roamly_core
```

Additional rules:

- Feature packages must not directly import one another.
- The application composition root connects features through contracts and
  provider overrides.
- Public package APIs are exported from the package's top-level library.
- Implementation details remain under `lib/src`.
- DTOs stay with the feature that owns the backend contract.
- Domain entities never deserialize network JSON directly.

## Riverpod conventions

- `ProviderScope` is created once in the executable application.
- `Provider` exposes stable dependencies and repositories.
- `Notifier` manages synchronous state.
- `AsyncNotifier` manages asynchronous workflows.
- Views watch presentation state and invoke controller actions.
- Widgets do not call Dio clients, storage plugins, or repositories directly.
- Provider overrides are applied in the application composition root and in
  tests.

## Networking conventions

- Feature remote data sources depend on `ApiClient`, not directly on Dio.
- `DioApiClient` is the current HTTP transport adapter and is the only layer
  that performs ordinary Dio `get`, `post`, `put`, and `delete` calls.
- Public authentication calls and authenticated API calls use separately
  configured clients when necessary.
- Endpoint paths are feature-owned constants, such as `AuthApiPaths`; they are
  not collected in a global application endpoint file.
- Endpoint paths are relative and do not begin with `/`, so they preserve the
  versioned path in the configured base URL.
- Remote data sources own request payload construction and conversion from
  untyped response data into feature models.
- Concrete remote data sources are named for their role, for example
  `ApiAuthRemoteDataSource`, rather than for the underlying Dio adapter.
- Refresh-token requests must not recursively trigger the authentication
  interceptor.
- Concurrent unauthorized responses use a single-flight refresh operation.
- Access and refresh tokens are never logged.
- Transport exceptions are converted into typed feature failures.
- Request and response bodies containing user or credential data are not
  logged in production.
- The WebSocket connection uses a dedicated transport adapter rather than
  being forced through Dio.

The authentication request dependency chain is:

```text
AuthRepository
  -> AuthRemoteDataSource
  -> ApiAuthRemoteDataSource
  -> ApiClient
  -> DioApiClient
  -> Dio
```

## Navigation conventions

The app uses `MaterialApp.router` with `go_router`. The application owns the
route graph while feature packages provide screens and typed route arguments.

- Named routes from the legacy Navigator API are not used.
- Authentication redirects depend on observable authentication state.
- Deep links must resolve to the same state as in-app navigation.
- Bottom-tab state uses `StatefulShellRoute.indexedStack`.
- Preference onboarding will add a separate authenticated bootstrap gate.
  Preference loading failures must offer retry instead of being interpreted
  as completed or skipped onboarding.

## Preference feature boundaries

Preference domain, data, and presentation code initially lives under
`apps/roamly_app/lib/src/features/preferences`. It serves both onboarding and
future Profile editing. The existing `features/onboarding` Welcome screen is
the guest introduction and does not represent saved preference completion.

Domain entities remain pure Dart; data models own JSON parsing and enum wire
mapping. Display labels live in application localization. Authentication stays
in `roamly_auth`; application routing coordinates authentication and preferences.

See [Preference onboarding](preference-onboarding.md) for the current plan.

## Logging conventions

- The application creates the root logger and injects namespaced child loggers
  into packages at composition boundaries.
- Log operational state transitions, recoveries, mapped transport failures,
  and unexpected application errors.
- Do not log widget rebuilds, every successful HTTP request, request or response
  bodies, credentials, access tokens, refresh tokens, or personal data.
- Use structured fields with stable keys instead of interpolating values into
  messages. Known credential fields are defensively redacted by
  `roamly_logging`.
- Expected failures use `warning`; infrastructure failures use `error`; only
  uncaught application failures use `fatal`.
- Vendor observability integrations must be implemented as `LogSink` adapters
  so feature and domain code remain vendor independent.

## Design system and white-label support

- Features use `ThemeData`, `ColorScheme`, `TextTheme`, and typed theme
  extensions.
- Brand colors, typography, logos, and imagery are configured outside feature
  packages.
- Components expose semantic variants such as primary, secondary, destructive,
  and loading rather than brand-specific values.
- Accessibility, contrast, text scaling, and touch-target behavior are part of
  component tests.

## Testing strategy

- Domain objects and use cases receive unit tests.
- Repositories are tested against mocked data sources.
- Riverpod controllers use provider-container tests with overrides.
- Important screens receive widget tests.
- Backend contracts receive serialization and error-mapping tests.
- Authentication and WebSocket journeys receive focused integration tests.
- Live provider calls are excluded from the normal test suite.

## Deferred capabilities

The first release does not include social login, email verification, buses,
trains, or push notifications. Preference onboarding and database-backed Home
recommendations are in scope. Activity-based Trending and analytics remain
future work.
