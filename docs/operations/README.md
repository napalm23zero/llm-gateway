# Operations and Observability

The metrics, logs, and health checks that make every request explainable and every container verifiably healthy.

## Every request has to be explainable

Observability isn't a dashboard bolted on at the end. For any single request, the gateway should answer: why this provider, why was it cacheable, why did the semantic result pass, what did it cost, how much did the cache save, what was the similarity score, which safety checks ran, and was a fallback used. Three signals carry that: metrics, structured logs, health checks.

## Metrics

Exposed with `prometheus-client`, scraped by Prometheus, drawn in Grafana. Naming: `_total` is a counter, `_seconds` is a duration histogram.

```text
llm_gateway_requests_total
llm_gateway_request_duration_seconds
llm_gateway_time_to_first_token_seconds
llm_gateway_provider_requests_total
llm_gateway_provider_errors_total
llm_gateway_input_tokens_total
llm_gateway_output_tokens_total
llm_gateway_estimated_cost_usd_total
llm_gateway_cache_hits_total
llm_gateway_cache_misses_total
llm_gateway_semantic_candidates_total
llm_gateway_semantic_rejections_total
llm_gateway_semantic_false_hits_total
llm_gateway_fallbacks_total
```

Example labels:

```text
provider
model
tenant
cache_mode
cache_status
response_status
fallback_reason
safety_rejection_reason
```

Two hard rules on every metric:

- **Low cardinality only.** Raw prompts, per-request ids, and unbounded entity names never become label values. Each distinct value is a new time series, and that's how you murder Prometheus.
- **No prompt text.** Metrics never carry prompt or response text, same rule as [security](../security/README.md).

## Structured logging

Logs are structured so a request can be reconstructed and correlated across services, not grepped out of free-form text by hand.

| Field | Purpose |
|---|---|
| `timestamp` | When the event occurred |
| `level` | Severity (info, warn, error) |
| `service` | Which component emitted the log |
| `request_id` | Correlates all logs for one gateway request |
| `trace_id` | The correlation ID propagated across services to stitch one request together |
| `tenant_id` | Which tenant the request belongs to |
| `operation` | What the component was doing (cache lookup, provider call) |
| `status` | Outcome of the operation |
| `duration` | How long it took |
| `error_code` | Stable code when it failed |

Never log secrets or prompt bodies: log the correlation ids and outcomes, not the content.

## Health checks

A running process is not a healthy service. A container can sit there with a green checkmark while its database is dead, its cache unreachable, and every provider timing out. A health check exists so you find that out from a probe, not from an angry user. It verifies real behavior, not just that the process is alive:

- **Liveness.** Is the process running and not deadlocked? Fail it and the container restarts.
- **Readiness.** Can it do its job right now? It checks the real dependencies (pgvector, Redis, provider reachability) before saying "send me traffic."

Declared per container in Compose, they're what one-command startup waits on before calling the platform ready.
