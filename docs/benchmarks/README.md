# Benchmarks

The reproducible benchmark suite: the workloads, the cache modes it compares, the report, and the metadata every number has to carry to mean anything. Values stay TBD until they reproduce. The hypothesis behind it: [../experiments/README.md](../experiments/README.md).

## Workloads

Nine categories: identical repeats, paraphrased equivalents, negation changes, numeric changes, time-sensitive prompts, tenant-specific prompts, high-concurrency duplicates, long-tail unique prompts, and mixed realistic traffic.

## Modes

Each workload runs against five modes:

A. No cache
B. Exact cache only
C. Semantic cache, no safeguards
D. Semantic cache, safeguards on
E. Semantic cache, shadow mode

## The report

| Scenario | Provider calls | Cache hits | False hits | P95 latency | Est. cost |
|---|---|---|---|---|---|
| No cache | TBD | 0% | 0% | TBD | TBD |
| Exact cache | TBD | TBD | 0% | TBD | TBD |
| Raw semantic cache | TBD | TBD | TBD | TBD | TBD |
| Protected semantic cache | TBD | TBD | TBD | TBD | TBD |

Dataset, config, and hardware ship with the results.

## Reproducibility

A benchmark number with no context to rerun it isn't a result, it's an anecdote. Every published result records: the exact **commit**, the **dataset version**, the **service config** (routing and safeguard toggles), the **model config** (provider, model, embedding model, versions), the **cache config** (mode, threshold, candidate count, TTL, active safeguards), the **hardware** and **container resource limits**, the **request count** and **concurrency** per scenario, the **warm-up** behavior, the measured **duration**, and the **processing method** (percentile, aggregation, outlier handling).

Numbers land here only after they reproduce from this metadata. A number I can't reproduce is marketing, and I don't do marketing.
