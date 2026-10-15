# Project status

*Last updated: 15 October 2026. Update this page with every PR.*

powerkit is in development and **not ready for use**: results are not yet
fully validated. Validation runs are recorded in
[`validation-log.md`](validation-log.md).

## Where things are

- **Build phases 0–3 are done** ([build guide](build-guide.md), section 8):
  the design spec format and its checks, and an engine that runs every MVP
  design through its backend package.
- **Validated (full validation run passed):** 2 x 2 between and 2 x 2 mixed
  ANOVA (via Superpower); basic tests (via Spower) against analytic
  results, direct Spower calls and Type I error.
- **Built, not yet validated:** regression interactions (via
  InteractionPoweR); simple, parallel and serial mediation and moderated
  mediation, PROCESS models 4, 6, 7 and 14 (via power4mome). Their full
  validation runs have not been recorded yet.
- **Waiting on published values:** several validation tests still have
  `TODO_PUBLISHED_VALUE` placeholders (including the G*Power published
  examples for basic tests), to be transcribed by the maintainer.
- **Upstream:** two issues found while wrapping Spower and power4mome were
  reported and fixed upstream on GitHub; powerkit keeps its workarounds
  until the fixes reach CRAN ([conventions](conventions.md), Departures 4
  and 8).
- **App:** a prototype Shiny app for the 2 x 2 designs is in a draft PR
  (#4). It is not merged.
- **Validation on GitHub:** the first run of the `full-validation`
  workflow (basic chunk) failed while installing packages (a missing
  system library for igraph); fixed, and to be rerun.
- **Memory:** mediation and moderated-mediation simulations run in batches
  of at most 200 replications, so they no longer need more memory than an
  ordinary laptop has (an unbatched 10,000-replication run did). The
  validation can also run on GitHub, one chunk at a time
  ([validation log](validation-log.md), "Running the full validation on
  GitHub").

## What's next

1. Full validation runs for the mediation and moderated mediation chunks
   (on GitHub or locally, now that they run in batches), and the
   remaining published values.
2. Simulation versions of the 2 x 2 ANOVA Type I error tests (build guide,
   section 6, open items).
3. Binary X and W in regression interactions and mediation (proposed
   phase, build guide section 8), after the maintainer's decisions there.
4. Phase 4: script export, methods paragraph, citations and
   preregistration text.
5. Phase 5: the Shiny app.
