# AI Assistant

## Current status

The AI Assistant is implemented as an application feature under
`apps/roamly_app/lib/src/features/assistant`. It provides authenticated
WebSocket chat, durable local history, offline request replay, lifecycle-safe
heartbeats, Markdown response rendering, and versioned event decoding.

The backend remains the authority for conversation IDs, assistant message IDs,
generation results, and itinerary IDs. Flutter owns the local conversation ID,
optimistic user message, delivery state, and durable pending-request outbox.

## Feature structure

```text
features/assistant/
├── application/
│   └── factories/
├── composition/
├── data/
│   ├── database/
│   ├── mappers/
│   ├── models/
│   ├── repositories/
│   ├── serialization/
│   ├── services/
│   └── sources/
├── domain/
│   ├── entities/
│   ├── policies/
│   └── repositories/
└── presentation/
    ├── controllers/
    ├── pages/
    ├── providers/
    ├── states/
    └── widgets/
```

`AssistantModule` is the feature composition root. It constructs the Drift
database, local data source, WebSocket manager, socket protocol adapter,
heartbeat coordinator, realtime session, and repository. These resources are
application scoped for the authenticated user and are disposed when the user
or application container changes.

## Realtime architecture

The feature uses a raw WebSocket transport through `roamly_networking`. Socket
connection state and Assistant protocol readiness are separate states:

1. `WebsocketManager` authenticates with the current bearer token and opens the
   socket.
2. `DefaultAssistantSocketDataSource` waits for `connection.ready` before it
   allows application messages.
3. The ready event supplies heartbeat, idle-timeout, and outgoing-size limits.
4. `DefaultAssistantHeartbeatCoordinator` schedules one ping at a time and
   invalidates the current connection when its pong deadline expires.
5. Retryable failures reconnect with bounded exponential backoff and equal
   jitter. The default policy starts at one second, caps at thirty seconds, and
   allows eight retries.

Every connection has a monotonically increasing generation. Messages and timer
callbacks from an old generation are ignored, preventing a stale socket from
changing current state.

## WebSocket protocol

Flutter sends:

| Event | Purpose |
| --- | --- |
| `connection.ping` | Keep the authenticated connection alive. |
| `travel.request` | Submit one idempotent assistant request. |

Flutter currently handles:

| Event | Local result |
| --- | --- |
| `connection.ready` | Marks the Assistant protocol ready and configures limits. |
| `connection.pong` | Completes the active heartbeat cycle. |
| `travel.request.accepted` | Links the remote conversation and marks the user message `sent`. |
| `travel.request.rejected` | Marks the user message `failed` and removes its pending request. |
| `travel.response.processing` | Marks the user message `processing`. |
| `travel.input.required` | Validates typed airport clarification, stores its text response, completes the user message, and publishes the structured domain event. |
| `travel.response.completed` | Stores the assistant response and optional itinerary ID, then completes the user message. |
| `travel.response.failed` | Marks the user message `failed` and removes its pending request. |

All envelopes use protocol version `1`, an aware `sent_at` timestamp, and UUID
correlation fields. Unknown event types and malformed payloads are rejected at
the data boundary. Incoming and negotiated outgoing payload sizes are bounded.

### Structured airport clarification

`travel.input.required` is a terminal result for the current request. It may
contain one or two unresolved route endpoints. Each request identifies the
origin or destination field and is either:

- `selection_required`, containing two through five typed airport or city
  options; or
- `not_found`, containing no options and a question asking for clearer input.

The client validates and maps this payload into domain clarification entities.
Its human-readable `content` is stored as an assistant message, so the response
is visible even before dedicated airport-selection controls are implemented.
The user can send the selected IATA code as a new idempotent request.

## Local history and offline behavior

Drift schema version 2 contains:

- conversations scoped by authenticated owner;
- user and assistant messages with correlation and delivery state;
- pending requests used as a durable outbox.

Sending follows this order:

1. Create a stable client message ID and local conversation ID.
2. Persist the conversation, pending user message, and pending request in one
   local transaction.
3. Send only when the application protocol is ready.
4. Keep retryable transport failures in the outbox.
5. Replay pending requests in bounded keyset-paginated batches after readiness.
6. Remove the pending record only after a terminal rejection, failure,
   clarification, or completed response.

The backend uses `client_message_id` for idempotency. Concurrent sends with the
same ID are deduplicated locally, and a reused ID with different content is
rejected.

Delivery states are:

```text
pending -> sent -> processing -> completed
   |          |          |
   +----------+----------+-> failed
```

Terminal states do not regress when delayed events arrive. Local timestamps are
normalized to UTC, and server timestamps cannot move a message before its
client creation time.

## Presentation

Riverpod controllers manage the active conversation, message timeline, and send
state. The timeline watches Drift, supports bounded older-message pagination,
and keeps existing messages visible during recoverable failures.

User messages render as selectable plain text. Assistant messages use
`flutter_markdown_plus` for headings, emphasis, lists, code, blockquotes,
tables, and links. Remote Markdown images are deliberately blocked until the
application has an allowlisted image-loading policy with safe URL validation,
bounded downloads, caching, and failure placeholders.

The delivery indicator means:

- clock: locally pending;
- one check: accepted by the backend;
- ellipsis: backend processing;
- two checks: terminal response stored;
- error outline: rejected or failed.

## Security and observability

- The access token is read immediately before each connection attempt and is
  sent only in the authorization header.
- Credentials, WebSocket URIs, messages, provider payloads, and peer reasons
  are not written to logs.
- WebSocket logs contain allowlisted operational metadata such as generation,
  retry attempt, delay, failure kind, HTTP status, and close code.
- Logging failure cannot interrupt socket lifecycle or cleanup.
- Domain code does not depend on WebSocket, Drift, Riverpod, or logging SDKs.

## Validation

The feature has focused tests for request creation, database migration, Drift
ownership and persistence, event decoding, model mapping, socket generations,
readiness, heartbeat timing, repository replay and idempotency, Riverpod
controllers, and presentation widgets.

Current validation after adding `travel.input.required` support:

```text
flutter analyze  # no issues
flutter test     # 570 tests passed
```

## Remaining work

- Render typed airport choices as accessible selection controls.
- Persist structured clarification data so controls survive an app restart.
- Add backend conversation-history synchronization; current history is local
  Drift data plus realtime events received by this installation.
- Add backend-to-client structured cards for flights, hotels, places, and
  itineraries instead of relying only on prose.
- Add an allowlisted, cached external-image pipeline if remote images remain a
  product requirement.
- Add end-to-end trace correlation across WebSocket request, LangGraph,
  LangChain tool, internal MCP call, and provider call.
- Resolve the upstream `path_provider_foundation`/`objective_c` iOS simulator
  native-symbol issue before relying on affected builds for device validation.

