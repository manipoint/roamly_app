# Preference onboarding

## Current status

The backend implements preference read, replacement, skip, and curated Home
discovery endpoints. Flutter integration is in progress. Its router currently
sends authenticated users directly to Home, which is a placeholder.

The first domain enums have been added under `features/preferences`. Remaining
entities, DTOs, repositories, controllers, pages, and routing are planned.

## Screens and fields

| Screen | Input |
| --- | --- |
| Travel style | One primary style |
| Interests and budget | One to five interests, budget tier, trip pace |
| Discovery scope | Local, international, or both; selected home city if required |

Home city is explicitly selected through location search. This flow does not
request GPS or notification permissions. Home city provides recommendation
context; a trip can depart from a different city.

## Domain and transport

Keep these types under `features/preferences/domain/entities` initially:

- `preference_types.dart`: supported enums;
- `canonical_location.dart`: selected provider-qualified location;
- `user_preferences.dart`: saved preference and onboarding state.

Domain types do not parse JSON or import Flutter. The data layer maps backend
values such as `mid_range` and `local_culture` to Dart enum values. Do not send
enum `.name` directly. Labels and validation messages belong to localization.

## API contract

All paths below are relative to the configured `/api/v1/` base URI.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `users/me/preferences` | Read saved choices and completion state |
| PUT | `users/me/preferences` | Replace all choices and complete onboarding |
| POST | `users/me/onboarding/skip` | Complete onboarding without inventing choices |
| GET | `locations/resolve` | Explicit search for canonical location selection |
| GET | `home` | Suggested, Popular, and Featured discovery sections |

`local` and `international` require a canonical home location. `both` permits
no home location. Budget never determines geographic scope.

The backend returns default preferences with HTTP 200 for a new account.
`onboarding_completed` controls routing. `personalization_ready` controls
whether personalized suggestions are available. These flags are independent:
a skipped account can be completed without being personalized.

## State and routing plan

1. After login or session restoration, fetch preferences for the current user.
2. Show a loading state while reading; show retry on failure.
3. Open preference onboarding when completion is false.
4. Keep screen selections in a synchronous Riverpod draft controller.
5. Submit one PUT at the end, or the skip endpoint on explicit Skip.
6. Navigate to Home only after a successful completion or skip response.

An asynchronous controller owns server reads and saves. Prevent duplicate
submissions. Preserve drafts on save errors and keep pending deep links while
onboarding is required. Reset all user-specific state on logout/account change;
late responses from a previous account must not populate the current account.

## Cost and Home caching

Do not fetch preferences on widget rebuilds or save every chip selection.
Resolve locations on explicit searches, not every keystroke.

Home uses database content and deterministic ranking. It returns `suggested`,
`popular`, and `spotlight`; the current spotlight kind is `featured`.
Flutter must use that label instead of displaying Trending.

The Home response advertises a five-minute private cache lifetime. Dio does not
automatically implement persistent HTTP caching; client state/cache handling
must be explicit. Scope cached data to the account and invalidate it after
preference changes and logout. Provider calls remain tied to explicit searches.

## Implementation order

1. Domain enums and canonical location.
2. Saved preferences entity and editable draft.
3. DTOs, wire mapping, remote source, and repository.
4. Read/save controllers and synchronous draft controller.
5. Three responsive pages using `roamly_ui` components.
6. Router gate and pending deep-link handling.
7. Home response models, loading/error states, and destination cards.

Review and tests accompany each meaningful step. Test serialization, validation,
save failures, account changes, routing, and small-screen/text-scale behavior.
