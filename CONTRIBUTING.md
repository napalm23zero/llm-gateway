# Contributing

How to propose changes to the LLM Gateway. The project is being developed as a learning and engineering case study, so clear communication of intent matters as much as the code.

## Before you start

Issues, technical discussions, adversarial prompt examples, architectural suggestions, and benchmark improvements are welcome.

Before submitting a large change, please open an issue describing:

* The problem
* The proposed solution
* Relevant trade-offs
* How the change will be tested
* Which metrics may be affected

Opening the issue first keeps the design discussion visible and avoids large, unreviewable pull requests.

## Pull requests

A pull request should explain the change so a reviewer can understand it without reading every line first. Include:

* **What** changed
* **Why** it changed
* **How it was tested** (which tests ran, in containers)
* **Affected components** and any documentation updates
* **Risks** and results
* **Rollback** considerations when relevant

A feature is not complete until its relevant documentation (component README, architecture docs, ADRs, configuration docs, or benchmark reports) is updated.

## Commits

Use Conventional Commits so history communicates intent. The `type(scope): summary` form makes the change scannable and drives changelog tooling.

Preferred examples:

```text
feat(cache): add semantic cache shadow mode
fix(gateway): prevent cross-tenant cache lookup
docs(architecture): document provider fallback flow
test(cache): add negation false-hit scenarios
refactor(backend): isolate provider adapters
```

## Related documentation

* [Development](docs/development/README.md)
* [Architecture decisions](docs/decisions/README.md)
