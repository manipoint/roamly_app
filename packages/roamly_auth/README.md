# Roamly Auth

Authentication domain, data, secure-storage, and presentation foundations for
Roamly.

## Features

- email and password registration and login;
- access-token and refresh-token rotation;
- secure session persistence and restoration;
- current-device and all-device logout workflows; and
- framework-independent authentication domain contracts.

Social login and email verification are deferred from the first release.

## Remote API design

The remote authentication boundary is intentionally layered:

```text
AuthRepository
  -> AuthRemoteDataSource
  -> ApiAuthRemoteDataSource
  -> ApiClient
  -> DioApiClient
```

`AuthRemoteDataSource` is the contract. `ApiAuthRemoteDataSource` is the
production implementation for the backend API. It depends on public and
authenticated `ApiClient` instances rather than importing Dio.

Authentication endpoints are owned by the feature in `AuthApiPaths`. Paths
are relative, for example `auth/register`, so the configured `/api/v1/` base
path is preserved.

The API data source owns:

- authentication request payloads;
- selection of the public or authenticated client;
- validation that successful responses contain JSON objects; and
- conversion into authentication response models.

It does not catch Dio exceptions or map application failures. Transport
failures flow to the repository request executor, which converts them into
typed results.

## Security

- Tokens and passwords must never be logged.
- Tokens are stored as one versioned encrypted JSON value.
- Refresh uses the public client to avoid recursive bearer interception.
- Logout uses the authenticated client.
- Internal data and infrastructure classes remain under `lib/src` and are not
  exported as public feature API.
