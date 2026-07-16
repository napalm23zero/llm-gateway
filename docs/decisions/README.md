# Architecture Decisions

The calls I made and why, as ADRs. Same shape every time: status, context, decision, alternatives, consequences. The early ones are stubs on purpose. I'm not going to fake a decision before the benchmark hands me evidence, so a lot of this says TBD until it earns a real answer.

## Index

| ADR | Title | Status |
|---|---|---|
| [ADR-001](#adr-001-postgresql-and-pgvector) | PostgreSQL and pgvector | Proposed |
| [ADR-002](#adr-002-exact-cache-before-semantic-cache) | Exact cache before semantic cache | Proposed |
| [ADR-003](#adr-003-tenant-scoped-cache-namespaces) | Tenant-scoped cache namespaces | Proposed |
| [ADR-004](#adr-004-shadow-mode-before-activation) | Shadow mode before activation | Proposed |
| [ADR-005](#adr-005-provider-adapter-architecture) | Provider adapter architecture | Proposed |
| [ADR-006](#adr-006-similarity-is-not-a-safety-boundary) | Similarity is not a safety boundary | Proposed |
| [ADR-007](#adr-007-cost-accounting-methodology) | Cost accounting methodology | Proposed |
| [ADR-008](#adr-008-cache-invalidation-and-prompt-versioning) | Cache invalidation and prompt versioning | Proposed |
| [ADR-009](#adr-009-distributed-service-boundaries) | Distributed service boundaries | Accepted |
| [ADR-010](#adr-010-pipeline-stages-are-gateway-modules) | Pipeline stages are gateway modules | Accepted |
| [ADR-011](#adr-011-build-versus-buy) | Build versus buy | Accepted |
| [ADR-012](#adr-012-streaming-responses) | Streaming responses | Accepted |
| [ADR-013](#adr-013-co-located-per-service-docker-composition) | Co-located per-service Docker composition | Accepted |

---

## ADR-001: PostgreSQL and pgvector
**Status:** Proposed
**Context:** I need a primary datastore and a vector store. Running one system for both is less to operate and less to break.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-002: Exact cache before semantic cache
**Status:** Proposed
**Context:** Exact-match caching is safe and cheap, so checking it before I spend an embedding and a vector search skips cost and risk on the easy wins.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-003: Tenant-scoped cache namespaces
**Status:** Proposed
**Context:** A response made for one tenant can never leak to another just because the prompts rhyme. Lookups need hard tenant boundaries.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-004: Shadow mode before activation
**Status:** Proposed
**Context:** Thresholds and safeguards need tuning before real users touch cached answers. Shadow mode lets me score would-be hits offline without serving them.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-005: Provider adapter architecture
**Status:** Proposed
**Context:** Providers, embedding backends, and local models should be swappable behind one stable interface instead of welding the gateway to a single vendor.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-006: Similarity is not a safety boundary
**Status:** Proposed
**Context:** A high similarity score doesn't prove two prompts are interchangeable, so thresholding can't be the cache's only decision.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-007: Cost accounting methodology
**Status:** Proposed
**Context:** Any cost-reduction claim has to come from real traffic, which means a defined way to compute baseline, actual, and avoided cost.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-008: Cache invalidation and prompt versioning
**Status:** Proposed
**Context:** Cached answers go stale when prompts, templates, or models change, so the cache key has to fold in prompt and model version.
**Decision:** TBD
**Alternatives:** TBD
**Consequences:** TBD

---

## ADR-009: Distributed service boundaries
**Status:** Accepted
**Context:** Modular monolith or independent services? This is a production-engineering showcase, so I want boundaries that mirror how a real system scales, without inventing services just to look sophisticated.
**Decision:** Four application services, each earned by a real difference in scale or resource profile: **gateway** (I/O-bound public edge), **cache** (CPU-bound vector search and safety), **embeddings** (CPU/GPU-bound, heavy models in memory), **worker** (background job queue). Provider adapters stay in the gateway: their circuit-breaker and fallback state is on the hot path, so extracting them adds a hop and buys nothing.
**Alternatives:** A modular monolith (simpler to run, hides the scaling story). A finer split with a separate router or providers service (rejected: no independent scaling need, adds hot-path latency).
**Consequences:** More surface (four deployables, contracts, network failure modes to test) in exchange for independent scaling and isolated failure domains. The benchmark has to measure the inter-service latency the split adds. If a boundary doesn't earn its keep later, collapsing it is a fair follow-up.

---

## ADR-010: Pipeline stages are gateway modules
**Status:** Accepted
**Context:** The pipeline adds stages beyond caching (guardrails, routing, load balancing, prompt registry, token estimation, human review). Making each a service would bloat the topology with zero evidence any of them needs to scale alone.
**Decision:** Stages are modules inside the existing four services, not new services. Guardrails and the prompt registry live in the gateway and call `embeddings` for classification; the worker handles the review queue and evals off the hot path.
**Alternatives:** A service per stage (rejected: hot-path stages plus a hop each equals latency for no scaling win). A rules engine or sidecar per stage (rejected as premature).
**Consequences:** The gateway carries more, so its module boundaries have to stay clean and independently testable. Fast hot path, few deployables. Any stage can be extracted later if a benchmark proves it needs its own scale, same rule as ADR-009.

---

## ADR-011: Build versus buy
**Status:** Accepted
**Context:** This is a showcase. Its value is proving I understand LLM infrastructure, not that I can assemble popular tools. But reinventing solved infra (a driver, a web server, a time-series database) signals the opposite: someone who doesn't know the ecosystem.
**Decision:** Build the parts that are the point by hand, buy the commodity infra that isn't. By hand: the semantic cache and its safety checks, provider adapters (no LiteLLM), the router, guardrails, cost and token accounting, single-flight stampede locks, the job queue (Postgres `SELECT ... FOR UPDATE SKIP LOCKED`, no Celery or RabbitMQ), SQL migrations (versioned `.sql` plus a runner, no Alembic), data access (SQL over asyncpg, no ORM), correlation-ID tracing through the logs (no OpenTelemetry or Jaeger), and the load-test benchmark (asyncio plus httpx, no k6). Bought: FastAPI, Uvicorn, Pydantic, asyncpg, Redis, PostgreSQL with pgvector, sentence-transformers, Prometheus, Grafana.
**Alternatives:** Buy everything (LiteLLM, Celery + RabbitMQ, Alembic, OpenTelemetry + Jaeger, k6), rejected because it hides the exact skills this repo exists to show. Build everything down to a web server or a driver, rejected as reinventing solved problems.
**Consequences:** More code to own, and the burden of doing the handmade parts well, since a badly built queue or tracing would sink the whole repo. The payoff is a portfolio piece where the hard internals are legible in the source. The queue is deliberate: I learn Celery and RabbitMQ in my separate async-backend repo, so building one here shows range instead of repeating a tool.

---

## ADR-012: Streaming responses
**Status:** Accepted
**Context:** In production, most LLM responses stream token by token. A gateway that only returns whole responses is unrealistic and the first gap a reviewer would spot. Streaming also touches the hardest stages.
**Decision:** Streaming (SSE) is a core capability from Phase 1, not an afterthought. That forces four answers up front: caching (store only after the stream completes; a mid-stream disconnect stores nothing), cost accounting (count tokens as they stream, record the total on close), output guardrails (filter as it flows, since buffering first defeats streaming), and shadow mode (compare a fresh stream against the would-be hit after it closes, off the hot path).
**Alternatives:** Buffer and return whole responses (simpler, but not how real apps behave, and it hides the interesting problems). Add streaming later in Phase 5 (rejected: caching and guardrails have to be designed around it from the start or they get reworked).
**Consequences:** Every in-path stage handles a stream, not a value. More complex, but realistic. Cache-on-complete means a stream that dies partway is a clean miss, never a partial entry.

---

## ADR-013: Co-located per-service Docker composition
**Status:** Accepted
**Context:** The platform is several services plus infra. One giant root compose file puts every build, volume, and healthcheck detail miles from the code it describes and turns into a merge-conflict magnet every service change has to fight over. I also need a dev container that reuses the same definitions instead of duplicating them.
**Decision:** Each service owns a co-located `.docker/` (its Dockerfile plus a base compose defining only that service, production-shaped: build and healthcheck, no reload, no mounts, no ports). A root `.docker/docker-compose.yml` aggregates them with Compose `include:`, one line per service. Environment differences are `-f` overlays at the root: `docker-compose.dev.yml` (reload, bind mounts, ports) and `docker-compose.test.yml` (test run). The dev container reuses the same base and dev overlay and just adds a `workspace` service that mounts the host Docker socket.
**Alternatives:** One monolithic root compose plus overlays (rejected: divorces infra from code, becomes a contention hotspot). Docker-in-Docker for the dev container (rejected as heavier than needed; the socket mount reaches just as far).
**Consequences:** Each service is self-contained and buildable in isolation, and adding one is a single `include:` line plus its `.docker/`. Base files stay production-shaped, so the test overlay and benchmarks measure something close to prod. Cost: the socket-mount dev container runs sibling containers on the host daemon, so bind-mount paths resolve against the host filesystem, a docker-outside-of-docker gotcha when wiring volumes.
