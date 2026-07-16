# Experiments

The semantic cache experiment: the hypothesis, the metrics that settle it, the cost model, and how I judge correctness. Every measured value stays TBD until it reproduces. Benchmark mechanics: [../benchmarks/README.md](../benchmarks/README.md).

## The hypothesis

> A semantic cache can meaningfully cut model calls, latency, and token cost on repetitive workloads without materially hurting answer quality.

The experiment tests whether that's actually true. The core trade-off: how much money can semantic caching save before similarity starts wrecking correctness?

## Primary metrics

| Metric | What it is |
|---|---|
| Exact cache-hit rate | Requests served by an identical prompt |
| Semantic cache-hit rate | Requests served by a similar past prompt |
| Provider-call reduction | Requests that dodge an LLM call |
| Input/output-token reduction | Tokens not sent or regenerated because of caching |
| Estimated cost reduction | Provider cost avoided by hits |
| P50 / P95 latency | Median and tail latency under load |
| False-hit rate | Semantic hits that never should have been reused |
| Cache precision | Share of semantic hits that were actually correct |
| Cache rejection rate | Similar results the safeguards threw out |

## Cost delta

```text
baseline_cost = cost_without_cache
actual_cost   = embedding_cost + cache_infrastructure_cost + provider_cost_after_cache
cost_reduction_% = (baseline_cost - actual_cost) / baseline_cost × 100
```

`embedding_cost` is generating query embeddings; `cache_infrastructure_cost` is the vector store (pgvector) plus the exact cache (Redis). The number comes from measured traffic, not a marketing slide. Cost reduction, provider-call reduction, P95 improvement, false-hit rate: all TBD until measured.

## Correctness

Cost reduction alone isn't a win. A cache that saves 40% but is wrong 2% of the time isn't a cache, it's a random-answer generator with good PR. So I check semantic equivalence, factual and instruction consistency, entity/number/negation preservation, and temporal and tenant-context consistency, using deterministic rule checks, golden test cases, human review, embedding-distance analysis, diffing against a fresh response, and LLM-as-judge. LLM-as-judge is just one more probabilistic component (a model grading a model is turtles all the way down), so it's a signal weighed against the deterministic checks, never ground truth.

## Continuous evals

Evaluation isn't a one-shot gate at merge time, it's a standing loop fed by the metrics and correlation IDs every stage emits (stage 7 in [../architecture/request-pipeline.md](../architecture/request-pipeline.md)). It tracks cost per request and tenant, sampled quality on live traffic, P50/P95 latency split by hit/miss/provider, and token usage per model. On top of that, model-vs-model A/B: same prompts, two candidates, scored, so a cheaper or faster model gets adopted only when its quality holds. Results feed back into routing and thresholds.

## Human-in-the-loop

When an output drops below a confidence threshold, a human validates or fixes it in a review queue before the user sees it, instead of shipping a guess. Every reviewed interaction (prompt, output, verdict) is kept as labelled data, which is what makes later fine-tuning possible: the traffic that exposed a weakness becomes the material to fix it. The queue runs on the `worker`, off the hot path, so a human decision never blocks a live response.

## Questions this answers

- Is semantic caching worth it after embedding and infra costs?
- Which workloads give the highest *safe* hit rates?
- How do I pick similarity thresholds?
- When does exact caching beat semantic?
- How often do false hits happen, and which language patterns cause the most dangerous ones?
- Do deterministic safeguards materially improve precision, and when should a second model validate a result?
- How does semantic caching stay safe multi-tenant, and under concurrent repeated traffic?
- Can the system explain every cache decision?

## Planned write-ups

1. I built a semantic cache for my LLM gateway
2. The real cost of a semantic cache
3. The one query pattern where my cache lied to users
4. Why cosine similarity is not a correctness guarantee
5. A multi-tenant LLM cache that doesn't leak data
6. Preventing cache stampedes in LLM apps
7. Exact vs semantic caching: what the benchmark taught me
8. Building an explainable LLM routing layer
