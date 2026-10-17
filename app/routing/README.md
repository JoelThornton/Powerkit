# app/routing — routing prototype

A clickable prototype of the routes in `docs/decision-tree.md`. Routing
only: no calculations. The input screens check a design spec with the
engine's `validate_spec()`, read-only. How to run it, record decisions and
run the tests: [`docs/routing-prototype.md`](../../docs/routing-prototype.md).

- `tree.yaml`: the single source of truth for routes, questions, end points,
  the guided route and the undecided settings.
- `app.R`: the Shiny app (reads `tree.yaml`).
- `R/tree.R`: helpers for the data (reachability, guided-route rules).
- `R/ui.R`: screen builders.
- `tests/`: testthat tests (`testthat::test_dir("app/routing/tests/testthat")`).
