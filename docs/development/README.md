# Development

Run the gateway locally, configure it, call it. Everything runs in containers, so your host stays clean.

## Local setup

Development goes through `.devcontainer/`: Python 3.12, package managers, linters, and formatters live inside the containers, never on your machine. You need Docker, Docker Compose, and a shell.

```bash
./run.sh      # UNIX
run.bat       # Windows in case you are not a real nerd
```

`run.sh` validates prerequisites, builds the images, starts the services, waits for health, runs migrations, and prints the URLs.

- **Tests** run inside containers through Compose (`./run.sh test`).
- **Benchmark** also runs in containers; workloads and modes are in the [benchmark docs](../benchmarks/README.md).

Exact commands land as the implementation does.

## Config

Behavior is externalized. Cache, routing, observability:

```yaml
gateway:
  cache:
    exact:
      enabled: true
      ttl: 1h
    semantic:
      enabled: true
      mode: shadow
      similarity-threshold: 0.93
      max-candidates: 5
      ttl: 1h
      safeguards:
        detect-negation-changes: true
        compare-numbers: true
        compare-dates: true
        compare-entities: true
        require-same-tenant: true
        require-same-system-prompt-version: true
  routing:
    default-profile: gateway-balanced
  observability:
    record-token-usage: true
    record-estimated-cost: true
    expose-prometheus-metrics: true
```

## API

### Request
```http
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer <token>
X-Tenant-ID: example-company
```

```json
{
  "model": "gateway-balanced",
  "messages": [
    {
      "role": "user",
      "content": "How can I reset my account password?"
    }
  ],
  "cache": {
    "mode": "semantic",
    "ttlSeconds": 3600
  }
}
```

### Response
```json
{
  "id": "req_01J...",
  "model": "provider-model-name",
  "response": {
    "role": "assistant",
    "content": "..."
  },
  "usage": {
    "inputTokens": 0,
    "outputTokens": 0,
    "estimatedCostUsd": 0
  },
  "gateway": {
    "cacheStatus": "SEMANTIC_HIT",
    "similarity": 0.947,
    "providerCalled": false,
    "latencyMs": 34
  }
}
```

### Streaming
Set `"stream": true` for Server-Sent Events, one token chunk per event:

```text
data: {"delta": {"content": "To "}}
data: {"delta": {"content": "reset "}}
data: {"delta": {"content": "your password, ..."}}
data: {"gateway": {"cacheStatus": "MISS", "providerCalled": true}}
data: [DONE]
```

A streamed response is cached only after the stream finishes cleanly, and token and cost totals are recorded on close (ADR-012).

## See also
- [Architecture decisions](../decisions/README.md)
- [Contributing](../../CONTRIBUTING.md)
