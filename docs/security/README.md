# Security and Privacy

How the gateway protects tenant data, keeps the cache from quietly becoming a data-leak machine, and treats security as a design input instead of a cleanup pass.

## Why this matters

A cache exists to reuse a past response, and reuse is exactly what leaks data when the boundaries are wrong. That's how an LLM cache quietly turns into a data-leak system with extra steps, which is why security here is a design input from the first commit, not a coat of paint at the end.

## First-class concerns

- Strict tenant isolation
- Cache namespace separation
- Encryption in transit
- Secret-management integration
- Configurable response retention
- Prompt and response redaction
- Sensitive-data detection
- Audit trails
- No raw prompts in metrics or logs
- Cache deletion by tenant or request
- Protection against prompt-based cache poisoning

The "no raw prompts" part is enforced on the [operations side](../operations/README.md): bounded labels, no prompt text, no secrets in logs.

## Guardrails

The trust boundary around every provider call. Prompts and responses may pass through third-party models on the open internet, so guardrails run both directions: nothing sensitive crosses unmasked, nothing unsafe comes back unchecked. Stages 1 and 6 of the [pipeline](../architecture/request-pipeline.md).

- **In (stage 1):** regex masks PII so raw identifiers never leave, and an optional small-model classifier (from `embeddings`) flags or blocks unsafe content. Masked, rejected, or passed through.
- **Out (stage 6):** content-policy checks and redaction on the response.

## Tenant isolation is non-negotiable

The hardest line in the project: a cached response made for one tenant must never reach another just because the prompts are similar. Get this wrong once and it's not a bug ticket, it's an incident report and a very uncomfortable email. The only exception is an explicitly shared public namespace.

A high similarity score says nothing about who's allowed to see the answer. So tenant identity is a boundary the cache enforces *before* similarity is even considered:

- Every lookup is scoped to the caller's tenant and namespace.
- Exact tenant and namespace match is a precondition for any semantic hit, not one signal among many.
- A cross-tenant lookup is a bug, and tenant-isolation attempts are in the failure-scenario tests.

## What should not be cached

Cache policy should be explicit, not accidental. Exclude requests that carry personal or tenant-specific data, real-time needs, side-effecting tool calls, auth decisions, financial operations, high-impact medical or legal decisions, non-deterministic workflows, explicit cache-control directives, freshness-sensitive prompts, or unsupported multimodal content.

**Sensitive operations bypass the semantic cache by default.** On these, a false hit doesn't return a slightly stale answer, it can approve the wrong action, expose the wrong record, or run against the wrong environment. When a wrong answer is that expensive, the safe default is to skip the cache and call the provider.

## Least-privilege containers

Every container runs with the least privilege it needs: minimal base images, multi-stage builds, non-root users, limited capabilities, explicit ports, health checks, and no embedded secrets. Secrets stay out of images and out of git, injected through environment variables or Docker secrets, never committed.

## Keys and quotas

Centralization as a security control. The gateway holds one master key instead of handing an API key to every developer and service, which would just multiply where it can leak (laptops, `.env` files, images, CI logs). Callers authenticate to the gateway, the gateway holds the provider credentials, and those never leave: one place, injected not embedded, easy to rotate. Per-tenant quotas are the other half, capping spend so one caller can't burn everyone's budget.

## Disclaimer

Experimental. Semantic caching can return wrong or stale answers when two requests are similar but not equivalent. Don't enable it blindly for sensitive, personalized, real-time, or high-impact use cases. Benchmark and configure per workload.
