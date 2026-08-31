# Roamly Networking

Shared HTTP transport infrastructure for Roamly applications and feature
packages.

## Features

- environment-aware API configuration;
- a transport-neutral `ApiClient` contract;
- a Dio-backed `DioApiClient` adapter;
- separately configured public and authenticated clients;
- bearer-token interception without credential logging;
- centralized Dio failure mapping; and
- typed request execution through `Result`.

## Boundaries

This package owns transport mechanics. It does not own feature endpoint paths,
request DTOs, response models, response parsing, or business rules. Those stay
inside the feature package that owns the backend contract.

Feature code depends on `ApiClient`; it does not depend directly on Dio:

```text
Feature remote data source -> ApiClient -> DioApiClient -> Dio
```

Public and authenticated API access should use distinct `ApiClient` instances.
The authenticated instance receives the bearer-token interceptor, while public
login, registration, and token-refresh requests must not trigger it.

## Path rules

- Pass relative paths such as `auth/login`.
- Do not begin paths with `/`; doing so can replace the versioned base path.
- Keep endpoint constants in their owning feature package.

## Security

Never log access tokens, refresh tokens, passwords, authorization headers, or
credential-bearing request and response bodies.
